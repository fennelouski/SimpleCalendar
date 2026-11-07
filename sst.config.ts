/// <reference path="./.sst/platform/config.d.ts" />
export default $config({
  app(input) {
    if (input.stage !== 'parallel') throw new Error('Only the protected parallel stage is enabled.');
    return { name: 'calendar-play', home: 'aws', removal: 'retain', protect: true,
      providers: { aws: { region: 'us-west-2', allowedAccountIds: ['074861507225'] } } };
  },
  async run() {
    if (!/^[a-f0-9]{40}$/.test(process.env.SOURCE_COMMIT || '')) throw new Error('SOURCE_COMMIT must identify the committed release.');
    const { previewRequest, previewResponse } = await import('./scripts/aws-preview.mjs');
    const password = new sst.Secret('PreviewPassword');
    const openAI = new sst.Secret('OpenAIAPIKey');
    const unsplash = new sst.Secret('UnsplashAccessKey');
    const site = new sst.aws.Nextjs('Site', {
      buildCommand: 'npm run build:aws', openNextVersion: '3.10.4', protection: 'oac',
      server: { runtime: 'nodejs24.x', memory: '1024 MB', timeout: '60 seconds' },
      transform: { server(args) { args.logging = { retention: '1 week' }; } },
      environment: { OPENAI_API_KEY: openAI.value, UNSPLASH_ACCESS_KEY: unsplash.value, SOURCE_COMMIT: process.env.SOURCE_COMMIT! },
      edge: { viewerRequest: { injection: password.value.apply(previewRequest) }, viewerResponse: { injection: previewResponse } },
    });
    return { url: site.url, functionURL: site.nodes.server?.url, functionName: site.nodes.server?.name, revision: process.env.SOURCE_COMMIT };
  },
});
