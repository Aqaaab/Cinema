# Contributing to Cinema

Thanks for considering a contribution. Cinema prioritizes correctness, rights compliance, accessibility, and a maintainable codebase over feature count.

## Before starting
1. Search existing issues and pull requests.
2. For substantial changes, open an issue or discussion first.
3. Read [the architecture](docs/ARCHITECTURE.md), [rights policy](docs/RIGHTS_AND_CATALOG_POLICY.md), and [security policy](SECURITY.md).
4. Keep changes focused. Avoid unrelated rewrites and dependency churn.

## Required checks
- API: `cd services/api && gofmt -w . && go test -race ./... && go vet ./...`
- Web: `cd apps/web && npm install && npm run typecheck && npm run build`
- Android: build the debug variant and run unit tests from Android Studio or Gradle.

All pull requests must pass repository CI. Add tests for behavior changes and update documentation when contracts change.

## Provider integration requirements

Provider adapters must be reviewed and explicitly approved. A contribution must include official provider documentation; the playback method allowed by current terms; territories, validity dates, attribution, ad, download, and embed restrictions; a strict host allowlist and test fixture; and a removal / revocation path.

Do not submit arbitrary JavaScript extensions, scraping logic, DRM circumvention, credential harvesting, open proxies, or links to unauthorized streams.

## Pull request checklist
- [ ] Scope is focused and explained.
- [ ] Tests cover new or changed behavior.
- [ ] No secrets, signed URLs, or user data are committed.
- [ ] Rights and licensing implications are documented.
- [ ] Accessibility and low-end device impact have been considered.
- [ ] Docs and examples match the implementation.
