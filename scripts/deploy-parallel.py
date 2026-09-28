#!/usr/bin/env python3
"""Build on this computer and deploy one committed revision to both hosts."""
import argparse
from datetime import datetime, timezone
import io
import json
import os
import secrets
from pathlib import Path
import shutil
import subprocess
import tarfile
from urllib.parse import urlsplit

REPO = Path(__file__).resolve().parent.parent
PROJECTS = {'calendar-play': 'prj_4RORB7yxSp0PDKKYQjdgaOjFezN6', 'calendar-play-api': 'prj_l0oRmqlOxaYzCBpXLfCCxeuYbgpj'}
TEAM = 'team_4XxwBQjEz3krxaqWiyyw7O0d'
ACCOUNT = '074861507225'
CUTOFF = datetime(2026, 10, 22, 7, tzinfo=timezone.utc)


def output(command, **kwargs):
    return subprocess.check_output(command, text=True, **kwargs).strip()


def deployment_url(result):
    # CLI56 emits {status, deployment:{url,...}} in non-interactive mode.
    # Older interactive CLI versions emitted a single URL line.
    try:
        payload = json.loads(result)
    except json.JSONDecodeError:
        candidate = result.strip()
    else:
        deployment = payload.get('deployment', payload) if isinstance(payload, dict) else {}
        candidate = deployment.get('url') if isinstance(deployment, dict) else None
    if not isinstance(candidate, str) or not candidate.strip():
        raise RuntimeError('Vercel succeeded but did not return a deployment URL; inspect the deployment before recording success.')
    candidate = candidate.strip()
    if not candidate.startswith('https://'):
        candidate = 'https://' + candidate
    parsed = urlsplit(candidate)
    if not parsed.hostname or not parsed.hostname.endswith('.vercel.app') or parsed.path not in ('', '/') or parsed.query or parsed.fragment:
        raise RuntimeError('Unexpected Vercel deployment URL; inspect the deployment before recording success.')
    return candidate.rstrip('/')


def check_release():
    if datetime.now(timezone.utc) >= CUTOFF:
        raise RuntimeError('Parallel-deployment cutoff reached. Check actual cutover state; do not use this command after cutover.')
    if output(['git', 'diff', 'HEAD', '--name-only'], cwd=REPO):
        raise RuntimeError('Commit integrated source changes before deployment.')
    untracked = output(['git', 'ls-files', '--others', '--exclude-standard'], cwd=REPO).splitlines()
    unexpected = [path for path in untracked if Path(path).name != '.DS_Store' and not (path.startswith('Simple Calendar.xcodeproj/') and '/xcuserdata/' in path)]
    if unexpected:
        raise RuntimeError('Uncommitted source files must be reviewed before deployment.')
    remote = output(['git', 'remote', 'get-url', 'origin'], cwd=REPO)
    if remote not in ('https://github.com/fennelouski/SimpleCalendar.git', 'git@github.com:fennelouski/SimpleCalendar.git'):
        raise RuntimeError('Unexpected repository.')
    return output(['git', 'rev-parse', 'HEAD'], cwd=REPO)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--aws-only', action='store_true', help='Prepare AWS parity without changing the production Vercel alias.')
    parser.add_argument('--profile', default='fishbowl-head')
    parser.add_argument('--vercel-cli', default=shutil.which('vercel'))
    args = parser.parse_args()
    revision = check_release()
    if not args.vercel_cli:
        raise RuntimeError('Install the supported Vercel CLI first.')
    credentials = json.loads(output(['aws', 'configure', 'export-credentials', '--profile', args.profile, '--format', 'process']))
    env = dict(os.environ)
    env.pop('AWS_PROFILE', None)
    env.update(AWS_ACCESS_KEY_ID=credentials['AccessKeyId'], AWS_SECRET_ACCESS_KEY=credentials['SecretAccessKey'],
               AWS_REGION='us-west-2', AWS_DEFAULT_REGION='us-west-2', SOURCE_COMMIT=revision,
               VERCEL_ORG_ID=TEAM)
    if credentials.get('SessionToken'):
        env['AWS_SESSION_TOKEN'] = credentials['SessionToken']
    else:
        env.pop('AWS_SESSION_TOKEN', None)
    identity = json.loads(output(['aws', 'sts', 'get-caller-identity', '--output', 'json'], env=env))
    if identity['Account'] != ACCOUNT:
        raise RuntimeError('Unexpected AWS account.')
    subprocess.run(['npm', 'test'], cwd=REPO, env=env, check=True)
    staging_root = REPO / '.deploy' / revision
    if staging_root.exists():
        shutil.rmtree(staging_root)
    staging_root.mkdir(parents=True, mode=0o700)
    archive = subprocess.check_output(['git', 'archive', revision], cwd=REPO)
    project_envs = {}
    stages = {}
    try:
        # Read both existing production configurations before changing either host.
        for name, project_id in PROJECTS.items():
            staging = staging_root / name
            staging.mkdir(mode=0o700)
            with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
                tar.extractall(staging)
            project_env = dict(env, VERCEL_PROJECT_ID=project_id)
            subprocess.run([args.vercel_cli, 'pull', '--yes', '--environment', 'production', '--project', project_id, '--scope', TEAM], cwd=staging, env=project_env, check=True)
            secret_file = staging / '.vercel' / '.env.production.local'
            secret_file.chmod(0o600)
            secret_env = json.loads(output(['node', '--input-type=module', '-e', 'import {parseEnv} from "node:util";import {readFileSync} from "node:fs";process.stdout.write(JSON.stringify(parseEnv(readFileSync(process.argv[1],"utf8"))));', str(secret_file)]))
            keys = ['OPENAI_API_KEY', 'UNSPLASH_ACCESS_KEY', 'UNSPLASH_SECRET_KEY']
            project_envs[name] = {key: secret_env.get(key) for key in keys}
            if not all(project_envs[name].values()):
                raise RuntimeError('Existing provider configuration is incomplete.')
            if secret_env.get('API_SECRET_KEY'):
                raise RuntimeError('Authentication configuration changed; reconcile AWS before deploying.')
            stages[name] = (staging, project_env)
        if len({json.dumps(values, sort_keys=True) for values in project_envs.values()}) != 1:
            raise RuntimeError('The existing projects have different provider configuration; shared AWS parity needs review.')
        password_file = REPO / '.deploy' / 'preview-password'
        if not password_file.exists():
            descriptor = os.open(password_file, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(descriptor, 'w') as handle:
                handle.write(secrets.token_urlsafe(48))
        password_file.chmod(0o600)
        provider = project_envs['calendar-play']
        values = {'OpenAIAPIKey': provider['OPENAI_API_KEY'], 'UnsplashAccessKey': provider['UNSPLASH_ACCESS_KEY'], 'PreviewPassword': password_file.read_text().strip()}
        for name, value in values.items():
            subprocess.run(['npx', '--no-install', 'sst', 'secret', 'set', name, '--stage', 'parallel'], input=value, text=True, cwd=REPO, env=env, check=True, stdout=subprocess.DEVNULL)
        values.clear()
        project_envs.clear()
        if not args.aws_only:
            for staging, project_env in stages.values():
                subprocess.run([args.vercel_cli, 'build', '--prod', '--yes'], cwd=staging, env=project_env, check=True)
        subprocess.run(['npm', 'run', 'deploy:aws'], cwd=REPO, env=env, check=True)
        record = {'revision': revision, 'deployedAt': datetime.now(timezone.utc).isoformat(), 'mode': 'aws-preview' if args.aws_only else 'parallel',
                  'vercelDeployments': {}, 'aws': json.loads((REPO / '.sst/outputs.json').read_text()),
                  'verification': 'Required: authenticated AWS and both existing Vercel production live checks; activation alone is not verified parity.'}
        record_file = REPO / '.deploy/deployed.json'
        record_file.write_text(json.dumps(record, indent=2) + '\n')
        if not args.aws_only:
            for name, (staging, project_env) in stages.items():
                result = output([args.vercel_cli, 'deploy', '--prebuilt', '--prod', '--yes', '--meta', f'sourceCommit={revision}', '--env', f'SOURCE_COMMIT={revision}'], cwd=staging, env=project_env)
                record['vercelDeployments'][name] = deployment_url(result)
                record_file.write_text(json.dumps(record, indent=2) + '\n')
        print(json.dumps(record, indent=2))
    finally:
        shutil.rmtree(staging_root, ignore_errors=True)



if __name__ == '__main__':
    main()
