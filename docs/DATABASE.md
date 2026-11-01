# Database and Supabase deployment

## Isolation rule

The migration in supabase/migrations/ is intended for a **new, dedicated Cinema Supabase project**. Do not apply it to AUTOMATAIQ or any other existing project. No Supabase project, credentials, service-role key, or connection string is configured in this repository at this stage.

## Apply later

1. Create a separate Supabase project named Cinema.
2. Keep the database password and service-role key in a password manager / deployment secret store.
3. Review the migration in a disposable staging project first.
4. Apply migrations using the Supabase CLI linked to the dedicated Cinema project.
5. Run the RLS and rights integration test suite before connecting the API.
6. Add only the public project URL and anon key to public clients; keep service-role credentials exclusively in the API runtime.

The migration is not marked as production-applied or integration-tested yet.

## Data boundaries

### Public catalogue

Only titles with catalog_status = 'published' can be selected by anonymous and authenticated clients. Catalogue mutation, external IDs, providers, rights records, media assets, destinations, subtitles, health checks, and audit records have no client-facing RLS policies.

### Personal data

- user_lists, user_list_items, user_library_entries, and watch_progress are scoped through auth.uid().
- content_reports allow an authenticated user to submit and read their own report only. Moderation is service-role-only.
- Rights audit logs are server-only and intentionally immutable from client roles.

### Rights enforcement

A media asset must reference a rights grant for the same title and provider. A database trigger rejects a new asset unless the grant is approved, currently active, and explicitly permits the requested playback method. A destination host must exactly match a provider allowlist entry.

These database checks are only one layer. The playback API must re-check grant state, expiry, viewer territory, destination host, redirects, and any nested HLS playlists on every authorization request. A database row or a reachable HTTPS URL alone is not permission to play.

## Operational notes

- The migration assumes Supabase's standard auth.users, anon, authenticated, and service_role objects.
- It uses PostgreSQL features available in current Supabase Postgres versions.
- Apply it once through the migration system; do not manually replay it against an already migrated database.
- Backups, PITR, retention, account deletion, and privacy/legal obligations must be configured and verified before public beta.
- The current API does not connect to this schema. Its health endpoints are the only implemented HTTP routes today.
