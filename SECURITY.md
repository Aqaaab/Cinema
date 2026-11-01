# Security Policy

## Supported versions

Cinema is pre-alpha. Security fixes are applied to the default branch; there are no stable releases yet.

## Reporting a vulnerability

Do not publish exploitable vulnerabilities in public issues. Use GitHub's **Report a vulnerability** feature on this repository when available. Include affected commit / version, impact, reproduction steps, and a suggested mitigation. Do not include real user data or live credentials.

## Security principles
- Never commit API keys, signing keys, provider credentials, or production URLs containing secrets.
- Keep database access behind server-side authorization and row-level security.
- Treat provider metadata, media URLs, subtitles, and imported artwork as untrusted input.
- Validate URL scheme, DNS resolution, redirects, IP ranges, and every HLS child playlist before any server-side fetch.
- Never expose a generic URL fetcher or open media proxy.
- Do not disable TLS verification or bypass DRM / access controls.
- Downloads and playback must be authorized by an active rights grant.
- Log identifiers and outcomes, not credentials, signed URLs, or personal viewing details.

## Current limitations

Authentication, database access, provider ingestion, and media playback are not implemented yet. Health endpoints are not a production security audit or a statement that the whole platform is secure.
