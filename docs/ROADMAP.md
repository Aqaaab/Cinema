# Roadmap

This roadmap is ordered by dependencies. Dates are intentionally omitted until the team has a tested baseline and a realistic capacity estimate.

## M0 — Foundation
- [x] Public repository and product direction.
- [x] Android, web, and Go service starter structure (in progress).
- [x] Rights and security policies.
- [ ] First green CI run on GitHub.
- [ ] Automated dependency and secret scanning.
- [ ] Screenshots and a short architecture demo.

## M1 — Catalogue contract
- [ ] Finalize title / episode / asset / rights schemas.
- [ ] Add migrations and database integration tests.
- [ ] Add catalog API with pagination, filtering, and stable IDs.
- [ ] Add metadata provider interfaces (keys remain server-side).
- [ ] Add a review/admin workflow for rights grants.
- [ ] Add sample fixtures whose rights are clear and documented.

## M2 — Discovery beta
- [ ] Search, filters, title details, seasons, and episode pages.
- [ ] Availability by territory and provider.
- [ ] Subtitle, audio, accessibility, and quality metadata.
- [ ] Arabic and English localization; RTL quality checks.
- [ ] User watchlist, lists, and progress sync.
- [ ] Keyboard, screen-reader, and contrast testing.

## M3 — Authorized playback
- [ ] Approve the first provider integration using documented terms.
- [ ] Playback authorization API with fail-closed rights checks.
- [ ] Android Media3 player and web player adapter.
- [ ] Subtitle selection, audio selection, and adaptive quality.
- [ ] Provider health checks and authorized-source failover.
- [ ] Synthetic playback tests against owned / licensed fixtures.

## M4 — Public beta readiness
- [ ] Privacy policy and terms reviewed for launch jurisdictions.
- [ ] Account export / deletion and consent controls.
- [ ] Rate limits, abuse controls, and admin audit logs.
- [ ] Sentry / OpenTelemetry, uptime checks, alerts, and runbooks.
- [ ] Signed Android artifacts and reproducible release notes.
- [ ] Load, accessibility, security, and low-memory device testing.

## M5 — Community scale
- [ ] Docker Compose for self-hosted development where appropriate.
- [ ] Public API and adapter documentation.
- [ ] Reviewed provider contribution workflow.
- [ ] Localization contributor program.
- [ ] Transparent public roadmap and release cadence.
- [ ] Community governance for major changes.
