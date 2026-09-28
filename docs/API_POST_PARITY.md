# Native POST parity

Calendar Play prepares owned API requests with CryptoKit SHA-256 of the final buffered body. The original body, content type and credentials stay intact. Both the event parser and the consent-gated photo transport use this preparation. It applies only to registered Calendar Play HTTPS API hosts; Google, Wikimedia, Unsplash CDN and other third-party traffic is unchanged.

Owned POST/PUT/PATCH requests need a buffered body and cannot use a body stream. The maximum is 65,536 bytes, matching the existing API reader. A Unicode description can satisfy a character-count limit while exceeding the byte limit, so the final body is checked immediately before transport. This digest is an OAC payload requirement, not client authentication. AWS remains an operator-protected preview with IAM-protected Lambda; native production routing stays on Vercel.

Run `bash Tools/ReleaseChecks/run-api-request-checks.sh` for focused production-caller checks. The script intercepts actual `EventDescriptionParser.parse` and `UnsplashAPI.trackDownload` URLSession requests and verifies their outgoing digest. It also checks exact bytes, a standard SHA-256 vector, credential preservation, the 64 KiB boundary, a multi-byte parser overflow, third-party exclusion and disabled photo consent. Existing core and network/image checks remain in `run.sh` and `run-network.sh`.

The optional `--live` mode sends one synthetic AI request, one photo search and one download registration to each existing host. Set `CALENDAR_PREVIEW_PASSWORD` from the existing local `.deploy/preview-password` without printing it, and optionally `CALENDAR_API_EVIDENCE` to a private audit output path. The test bridge changes only the origin and AWS preview Authorization; the digest comes from production native code before interception. It does not substitute manual hash headers. No customer event data is used.

OpenNext is pinned to 3.10.4 in both the dependency and SST configuration. Compatible transitive updates resolve the full npm audit, including build-time dependencies. Release evidence records exact source, archive and deployment revisions. Older shipped clients are not changed by a website deployment; App Store upload and device UI verification remain separate work.

References: [AWS OAC payload requirements](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-lambda.html), [Vercel branch deployment guard](https://vercel.com/docs/project-configuration/git-configuration).
