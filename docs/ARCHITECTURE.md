# Cinema Architecture

**Status:** initial architecture baseline. **Decision:** build a modular product in a monorepo; keep deployable components independently testable.

## Product boundary

Cinema is a rights-aware discovery, personal-library, and playback client. It is not a general-purpose scraper, media re-hosting service, or open URL proxy. Media remains with the authorized rights holder / provider wherever possible.

## High-level topology

```text
Android (Kotlin / Compose / Media3) ─┐
                                    ├── HTTPS API (Go)
Web (Next.js / TypeScript) ─────────┘       │
                                            ├── Catalog + metadata
                                            ├── Rights registry
                                            ├── Playback authorization
                                            ├── Provider health
                                            └── User library / progress
                                                     │
                                            PostgreSQL + Auth
                                                     │
                                  Approved metadata and playback adapters
                                                     │
                              Rights-holder CDN / official embed / public-domain host
```

## Components

### Android — apps/android

Native Kotlin + Jetpack Compose. Media3 will be introduced behind a playback interface after the rights model and authorization flow are implemented. Keep the application responsive on devices with 4 GB RAM: paging, lazy lists, bounded image caches, no eager media prefetch, and conservative background work.

### Web — apps/web

Next.js App Router + TypeScript. The web client owns discovery pages, accessible title pages, and user-library surfaces. It must not receive provider secrets or act as a server-side arbitrary URL fetcher. Public title pages should be indexable only when the underlying metadata and artwork usage permit it.

### API — services/api

Go modular monolith first. Modules are separated by domain boundaries, not deployed as microservices prematurely:

- Catalog: titles, seasons, episodes, external identifiers.
- Rights: grant, territory, method, validity, attribution, and permitted actions.
- Playback: authorize a specific title / episode / user / territory / method.
- Providers: approved adapters and source-health observations.
- Library: favorites, lists, viewing progress, history, and sync.
- Administration: review queue, takedowns, audit log, and feature flags.

The initial API only exposes health and readiness endpoints. No database or external provider is currently connected.

## Core domain model

| Entity | Important fields |
|---|---|
| titles | id, type, canonical_title, year, synopsis, language |
| external_ids | title_id, namespace, external_id |
| seasons / episodes | series_id, season_number, episode_number, title_id |
| rights_grants | asset_id, licensor, license_reference, territory, valid_from, valid_until, permitted_methods, downloads_allowed |
| media_assets | title_id, asset_type, provider_id, playback_method, status |
| stream_sources | asset_id, host_id, priority, last_checked_at, health_state |
| subtitle_tracks | asset_id, language, format, accessibility_flags, source |
| watch_progress | user_id, asset_id, position_ms, duration_ms, updated_at |
| favorites / lists | user_id, title_id, list_id |
| provider_health | provider_id, region, checked_at, latency_ms, failure_class |
| audit_log | actor, action, object_type, object_id, timestamp |

A playable asset must reference an active rights grant. Database constraints and service authorization must enforce that relationship; a UI label alone is not enforcement.

## Provider adapter contract

Adapters are allowlisted, reviewed, and declarative where possible. Each adapter must declare provider identity, official documentation, permitted territories and playback methods, hostnames and redirect policy, subtitle / download / embed / ad rules, rights evidence, validity window, attribution, and revocation procedure.

Do not execute user-supplied provider scripts inside the API or clients. Adapter code is trusted code and requires maintainer review.

## Playback authorization

1. Client requests playback for a title / episode.
2. API resolves the asset and user's territory using a privacy-conscious method.
3. API verifies the grant is active, territory matches, and the requested method is allowed.
4. API checks provider health and returns a short-lived authorized playback descriptor.
5. Client plays directly from the approved provider / CDN / official embed.
6. Client reports coarse playback outcomes; signed URLs and viewing secrets are redacted from logs.

Failover is allowed only to another source that passes the same rights and territory checks. Availability must never override authorization.

## Security and privacy boundaries

- No public arbitrary URL fetch endpoint.
- Server-side URL validation must defend against SSRF, DNS rebinding, private IP ranges, redirects, and nested HLS playlists.
- Apply RLS to user-owned tables. Use separate server-side credentials and never ship service-role keys to clients.
- Minimize viewing-history collection and provide export / delete controls.
- Keep playback URLs out of analytics, logs, crash reports, and support tickets.
- Restrict admin actions and write every rights change to an immutable audit trail.

## Reliability and performance targets

Proposed objectives to validate after beta (not current measured results): 99.9% monthly API availability; discovery p95 under 400 ms excluding third-party provider latency; playback authorization p95 under 500 ms; crash-free sessions of at least 99.5% in beta, progressing to 99.8%; no unbounded image / media prefetch; missing, expired, or ambiguous rights grant means no playback.

## Deployment evolution

Start with one API service and managed PostgreSQL / authentication. Do not self-host a large video library or transcoding fleet in the first release. Split services only when measured load, team ownership, or security isolation justifies it. Use a provider CDN / official embed under contract instead of relaying all video through Cinema.
