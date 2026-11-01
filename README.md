# Cinema

<p align="center"><strong>Discover what you can actually watch. Free, transparent, and legal.</strong></p>

<p align="center">
  <a href="https://github.com/Aqaaab/Cinema/actions/workflows/ci.yml"><img src="https://github.com/Aqaaab/Cinema/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-7cdb9a.svg" alt="MIT License"></a>
  <a href="https://github.com/Aqaaab/Cinema/issues"><img src="https://img.shields.io/github/issues/Aqaaab/Cinema" alt="Issues"></a>
</p>

Cinema is an open-source discovery and personal-library platform for films, series, and animation. Its defining promise is simple: **a title is not marked as watchable until its source, usage rights, and territory rules have been checked.**

Cinema is being built for Android and the web, with a small Go API. It is designed to be fast on modest devices, transparent about where media comes from, and extensible without executing untrusted provider code.

> **Project status: early foundation / pre-alpha.** The repository contains starter applications and architecture foundations. A production catalogue, playback providers, account sync, and downloads are not connected yet. Do not use this project as a source of streaming links today.

## Why Cinema should exist

Most entertainment apps make discovery easy but make availability, regional restrictions, subtitle support, and source reliability hard to understand. Cinema aims to put those facts next to every title.

- **Proof of availability:** show the authorized source, territory, validity window, and last health check.
- **One personal library:** watchlist, watched history, progress, lists, and cross-device sync.
- **Accessible playback:** clear audio, subtitle, quality, and accessibility information before playback.
- **A calm, lightweight experience:** native Android UI, responsive web, paging, lazy loading, and low-memory defaults.
- **Open by design:** documented APIs, reproducible builds, transparent decisions, and community-reviewed provider integrations.

## Non-negotiable content rules

Cinema does not host, scrape, or redistribute media without permission. "Free to watch somewhere" does not automatically mean reusable or embeddable. Every playable item must have a documented rights grant or a provider integration whose terms explicitly authorize the intended playback method and territory. See [the rights policy](docs/RIGHTS_AND_CATALOG_POLICY.md).

## Repository layout

```text
apps/
  android/       Native Android app (Kotlin + Jetpack Compose)
  web/           Web app (Next.js + TypeScript)
services/
  api/           Go HTTP API
docs/
  ARCHITECTURE.md
  RIGHTS_AND_CATALOG_POLICY.md
  ROADMAP.md
  GROWTH_STRATEGY.md
.github/
  workflows/     Continuous integration
```

## Development quick start

### Requirements

- Go 1.27+
- Node.js 22+
- Java 21
- Android SDK 37 and Gradle 9.3.1+
- Android Studio with support for the configured Android Gradle Plugin

### Run the API

```bash
cd services/api
go test ./...
go run ./cmd/api
```

The API listens on `http://localhost:8080` by default.

- `GET /healthz` — liveness
- `GET /readyz` — readiness

### Run the web app

```bash
cd apps/web
npm install
npm run dev
```

Open `http://localhost:3000`.

### Build Android

Open `apps/android` in Android Studio and sync Gradle, or run:

```bash
cd apps/android
gradle :app:assembleDebug
```

The Android application is a UI foundation only; playback is intentionally disabled until a rights-verified source is configured.

## Current implementation

| Area | Status |
|---|---|
| Web application shell | Starter UI |
| Android application shell | Starter UI |
| Go API | Health/readiness endpoints + unit tests |
| Rights and source policy | Documented |
| Database and authentication | Not connected |
| Metadata providers | Not connected |
| Licensed playback adapters | Not connected |
| Downloads / offline playback | Not connected |
| Production deployment | Not configured |

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md) before opening a contribution. Feature proposals should include user value, accessibility impact, performance cost, and rights implications.

## Project direction

The first milestone is a working, tested discovery experience with a rights-aware catalogue contract. The longer-term roadmap is in [docs/ROADMAP.md](docs/ROADMAP.md). The plan for sustainable, organic open-source growth is in [docs/GROWTH_STRATEGY.md](docs/GROWTH_STRATEGY.md).

## License

Cinema is released under the [MIT License](LICENSE). This license covers this repository's code; it does **not** grant rights to third-party films, series, artwork, metadata, or trademarks.
