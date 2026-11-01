-- Cinema core schema for a NEW, isolated Supabase project.
-- Apply this migration only after creating the dedicated Cinema project.
-- Catalog and provider writes belong to the trusted server/service_role.

begin;

create or replace function public.cinema_valid_code_array(items text[], item_pattern text)
returns boolean language sql immutable strict as $$
  select cardinality(items) > 0
     and array_position(items, null) is null
     and not exists (select 1 from unnest(items) as u(item_value) where u.item_value !~ item_pattern);
$$;

create or replace function public.cinema_set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.titles (
  id uuid primary key default gen_random_uuid(),
  canonical_title text not null check (length(trim(canonical_title)) between 1 and 300),
  original_title text check (original_title is null or length(original_title) <= 300),
  title_type text not null check (title_type in ('movie', 'series', 'anime', 'documentary', 'short', 'episode')),
  release_year integer check (release_year is null or release_year between 1888 and 2200),
  synopsis text check (synopsis is null or length(synopsis) <= 12000),
  original_language text check (original_language is null or original_language ~ '^[a-z]{2,3}(-[A-Z]{2})?$'),
  catalog_status text not null default 'draft' check (catalog_status in ('draft', 'published', 'hidden', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index titles_published_type_year_idx on public.titles (title_type, release_year desc) where catalog_status = 'published';
create index titles_search_idx on public.titles using gin (to_tsvector('simple', coalesce(canonical_title, '') || ' ' || coalesce(original_title, '')));

create table public.seasons (
  id uuid primary key default gen_random_uuid(),
  series_title_id uuid not null references public.titles(id) on delete cascade,
  season_number integer not null check (season_number between 0 and 1000),
  season_name text check (season_name is null or length(season_name) <= 200),
  created_at timestamptz not null default now(),
  unique (series_title_id, season_number),
  unique (id, series_title_id)
);

create or replace function public.cinema_check_series_title()
returns trigger language plpgsql set search_path = public as $
declare
  parent_type text;
begin
  select title_type into parent_type from public.titles where id = new.series_title_id;
  if parent_type not in ('series', 'anime') then
    raise exception 'season parent must be a series or anime title' using errcode = '23514';
  end if;
  return new;
end;
$;

create trigger seasons_series_guard
before insert or update of series_title_id on public.seasons
for each row execute function public.cinema_check_series_title();

create table public.episodes (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  episode_number integer not null check (episode_number between 1 and 10000),
  episode_title_id uuid not null unique references public.titles(id) on delete cascade,
  air_date date,
  duration_ms bigint check (duration_ms is null or duration_ms > 0),
  created_at timestamptz not null default now(),
  unique (season_id, episode_number)
);

create or replace function public.cinema_check_episode_title()
returns trigger language plpgsql set search_path = public as $
declare
  episode_type text;
begin
  select title_type into episode_type from public.titles where id = new.episode_title_id;
  if episode_type <> 'episode' then
    raise exception 'episode_title_id must reference a title of type episode' using errcode = '23514';
  end if;
  return new;
end;
$;

create trigger episodes_title_guard
before insert or update of episode_title_id on public.episodes
for each row execute function public.cinema_check_episode_title();

create table public.title_external_ids (
  id uuid primary key default gen_random_uuid(),
  title_id uuid not null references public.titles(id) on delete cascade,
  namespace text not null check (length(trim(namespace)) between 1 and 60),
  external_id text not null check (length(trim(external_id)) between 1 and 180),
  created_at timestamptz not null default now(),
  unique (namespace, external_id),
  unique (title_id, namespace)
);

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  provider_key text not null unique check (provider_key ~ '^[a-z0-9][a-z0-9._-]{1,79}$'),
  display_name text not null check (length(trim(display_name)) between 1 and 160),
  homepage_url text not null check (homepage_url ~ '^https://'),
  terms_url text check (terms_url is null or terms_url ~ '^https://'),
  allowed_hosts text[] not null,
  provider_status text not null default 'pending_review' check (provider_status in ('pending_review', 'active', 'suspended', 'revoked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (public.cinema_valid_code_array(allowed_hosts, '^[a-z0-9.-]+$'))
);

create table public.rights_grants (
  id uuid primary key default gen_random_uuid(),
  title_id uuid not null references public.titles(id) on delete cascade,
  provider_id uuid not null references public.providers(id) on delete restrict,
  licensor text not null check (length(trim(licensor)) between 1 and 200),
  evidence_url text not null check (evidence_url ~ '^https://'),
  license_reference text not null check (length(trim(license_reference)) between 3 and 200),
  grant_status text not null default 'pending_review' check (grant_status in ('draft', 'pending_review', 'approved', 'suspended', 'revoked')),
  valid_from timestamptz not null,
  valid_until timestamptz not null,
  territories text[] not null,
  permitted_methods text[] not null,
  attribution text check (attribution is null or length(attribution) <= 1000),
  downloads_allowed boolean not null default false,
  caching_allowed boolean not null default false,
  reviewer_id text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, title_id, provider_id),
  check (valid_until > valid_from),
  check (public.cinema_valid_code_array(territories, '^[A-Z]{2}$')),
  check (public.cinema_valid_code_array(permitted_methods, '^(official_embed|direct_playback|download|cache)$')),
  check ((grant_status = 'approved' and reviewer_id is not null and reviewed_at is not null) or grant_status <> 'approved'),
  check (not downloads_allowed or permitted_methods @> array['download']::text[]),
  check (not caching_allowed or permitted_methods @> array['cache']::text[])
);
create index rights_grants_title_provider_idx on public.rights_grants (title_id, provider_id, grant_status);
create index rights_grants_validity_idx on public.rights_grants (valid_from, valid_until) where grant_status = 'approved';

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  title_id uuid not null references public.titles(id) on delete cascade,
  provider_id uuid not null references public.providers(id) on delete restrict,
  rights_grant_id uuid not null,
  playback_method text not null check (playback_method in ('official_embed', 'direct_playback', 'download', 'cache')),
  asset_status text not null default 'pending_review' check (asset_status in ('pending_review', 'active', 'disabled', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (rights_grant_id, title_id, provider_id) references public.rights_grants(id, title_id, provider_id) on delete cascade,
  unique (id, title_id)
);

create or replace function public.cinema_check_asset_rights()
returns trigger language plpgsql set search_path = public as $$
declare
  grant_row public.rights_grants%rowtype;
  provider_state text;
begin
  select provider_status into provider_state
  from public.providers where id = new.provider_id;

  if provider_state is distinct from 'active' then
    raise exception 'provider is not active' using errcode = '23514';
  end if;

  select * into grant_row from public.rights_grants
  where id = new.rights_grant_id and title_id = new.title_id and provider_id = new.provider_id;

  if not found then
    raise exception 'matching rights grant not found' using errcode = '23503';
  end if;
  if grant_row.grant_status <> 'approved' or now() < grant_row.valid_from or now() >= grant_row.valid_until then
    raise exception 'rights grant is not currently active' using errcode = '23514';
  end if;
  if not (grant_row.permitted_methods @> array[new.playback_method]::text[]) then
    raise exception 'playback method is not permitted by the rights grant' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger media_assets_rights_guard
before insert or update of title_id, provider_id, rights_grant_id, playback_method
on public.media_assets for each row execute function public.cinema_check_asset_rights();

create table public.media_destinations (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  destination_url text not null check (destination_url ~ '^https://'),
  destination_host text not null check (destination_host = lower(destination_host) and destination_host ~ '^[a-z0-9]([a-z0-9.-]{0,251}[a-z0-9])?
  label text check (label is null or length(label) <= 100),
  priority smallint not null default 100 check (priority between 0 and 1000),
  destination_status text not null default 'pending_review' check (destination_status in ('pending_review', 'active', 'disabled', 'removed')),
  created_at timestamptz not null default now(),
  unique (asset_id, destination_url)
);

-- Exact hostname match only. Redirects and nested HLS playlists still require runtime validation.
create or replace function public.cinema_check_destination_host()
returns trigger language plpgsql set search_path = public as $$
declare
  asset_provider_id uuid;
  host_allowed boolean;
  parsed_url_host text;
begin
  parsed_url_host := lower(substring(new.destination_url from '^https://([^/:?#]+)'));
  if parsed_url_host is null or parsed_url_host <> lower(new.destination_host) then
    raise exception 'destination_host must match the HTTPS URL hostname' using errcode = '23514';
  end if;

  select provider_id into asset_provider_id from public.media_assets where id = new.asset_id;
  if asset_provider_id is null then
    raise exception 'media asset not found' using errcode = '23503';
  end if;
  select exists (
    select 1 from public.providers p
    where p.id = asset_provider_id and lower(new.destination_host) = any(p.allowed_hosts)
  ) into host_allowed;
  if not host_allowed then
    raise exception 'destination host is not allowlisted for this provider' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger media_destinations_host_guard
before insert or update of asset_id, destination_url, destination_host
on public.media_destinations for each row execute function public.cinema_check_destination_host();

create table public.subtitle_tracks (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  language_code text not null check (language_code ~ '^[a-z]{2,3}(-[A-Z]{2})?$'),
  format text not null check (format in ('vtt', 'srt', 'ttml', 'imsc')),
  is_forced boolean not null default false,
  is_sdh boolean not null default false,
  track_status text not null default 'pending_review' check (track_status in ('pending_review', 'active', 'disabled', 'removed')),
  attribution text check (attribution is null or length(attribution) <= 500),
  created_at timestamptz not null default now(),
  unique (asset_id, language_code, format, is_forced, is_sdh)
);

create table public.provider_health (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers(id) on delete cascade,
  territory text not null check (territory ~ '^[A-Z]{2}$'),
  checked_at timestamptz not null default now(),
  latency_ms integer check (latency_ms is null or latency_ms >= 0),
  health_state text not null check (health_state in ('healthy', 'degraded', 'unavailable', 'unknown')),
  failure_class text check (failure_class is null or length(failure_class) <= 120),
  unique (provider_id, territory, checked_at)
);
create index provider_health_latest_idx on public.provider_health (provider_id, territory, checked_at desc);

create table public.user_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 100),
  description text check (description is null or length(description) <= 500),
  visibility text not null default 'private' check (visibility in ('private', 'unlisted', 'public')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);
create index user_lists_owner_updated_idx on public.user_lists (user_id, updated_at desc);

create table public.user_list_items (
  list_id uuid not null references public.user_lists(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  position integer not null default 0 check (position >= 0),
  note text check (note is null or length(note) <= 500),
  created_at timestamptz not null default now(),
  primary key (list_id, title_id)
);

create table public.user_library_entries (
  user_id uuid not null references auth.users(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  entry_type text not null check (entry_type in ('watchlist', 'favorite', 'watched')),
  created_at timestamptz not null default now(),
  primary key (user_id, title_id, entry_type)
);
create index user_library_entries_user_type_idx on public.user_library_entries (user_id, entry_type, created_at desc);

create table public.watch_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  position_ms bigint not null default 0 check (position_ms >= 0),
  duration_ms bigint check (duration_ms is null or duration_ms > 0),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, asset_id),
  check (duration_ms is null or position_ms <= duration_ms + 30000)
);
create index watch_progress_user_updated_idx on public.watch_progress (user_id, updated_at desc);

create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete restrict,
  title_id uuid references public.titles(id) on delete set null,
  provider_id uuid references public.providers(id) on delete set null,
  territory text check (territory is null or territory ~ '^[A-Z]{2}$'),
  report_type text not null check (report_type in ('rights', 'incorrect_metadata', 'broken_source', 'subtitle', 'accessibility', 'safety', 'other')),
  description text not null check (length(trim(description)) between 10 and 4000),
  report_status text not null default 'submitted' check (report_status in ('submitted', 'triaged', 'investigating', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table public.rights_audit_log (
  id bigint generated always as identity primary key,
  actor_id text not null,
  action text not null check (length(action) between 1 and 120),
  object_type text not null check (length(object_type) between 1 and 80),
  object_id text not null,
  change_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index rights_audit_log_object_idx on public.rights_audit_log (object_type, object_id, created_at desc);

create trigger titles_set_updated_at before update on public.titles for each row execute function public.cinema_set_updated_at();
create trigger providers_set_updated_at before update on public.providers for each row execute function public.cinema_set_updated_at();
create trigger rights_grants_set_updated_at before update on public.rights_grants for each row execute function public.cinema_set_updated_at();
create trigger media_assets_set_updated_at before update on public.media_assets for each row execute function public.cinema_set_updated_at();
create trigger user_lists_set_updated_at before update on public.user_lists for each row execute function public.cinema_set_updated_at();
create trigger watch_progress_set_updated_at before update on public.watch_progress for each row execute function public.cinema_set_updated_at();

alter table public.titles enable row level security;
create policy titles_published_read on public.titles for select to anon, authenticated using (catalog_status = 'published');

alter table public.title_external_ids enable row level security;
alter table public.seasons enable row level security;
alter table public.episodes enable row level security;
alter table public.providers enable row level security;
alter table public.rights_grants enable row level security;
alter table public.media_assets enable row level security;
alter table public.media_destinations enable row level security;
alter table public.subtitle_tracks enable row level security;
alter table public.provider_health enable row level security;
alter table public.rights_audit_log enable row level security;
alter table public.content_reports enable row level security;

alter table public.user_lists enable row level security;
create policy user_lists_owner_all on public.user_lists for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy user_lists_public_read on public.user_lists for select to anon, authenticated
using (visibility in ('public', 'unlisted'));

alter table public.user_list_items enable row level security;
create policy user_list_items_owner_all on public.user_list_items for all to authenticated
using (exists (select 1 from public.user_lists l where l.id = list_id and l.user_id = auth.uid()))
with check (exists (select 1 from public.user_lists l where l.id = list_id and l.user_id = auth.uid()));
create policy user_list_items_public_read on public.user_list_items for select to anon, authenticated
using (
  exists (
    select 1 from public.user_lists l
    where l.id = list_id and l.visibility in ('public', 'unlisted')
  )
);

alter table public.user_library_entries enable row level security;
create policy user_library_entries_owner_all on public.user_library_entries for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.watch_progress enable row level security;
create policy watch_progress_owner_all on public.watch_progress for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy content_reports_insert_own on public.content_reports for insert to authenticated
with check (reporter_user_id = auth.uid());
create policy content_reports_read_own on public.content_reports for select to authenticated
using (reporter_user_id = auth.uid());

revoke all on all tables in schema public from anon, authenticated;
grant select on public.titles to anon, authenticated;
grant select on public.user_lists, public.user_list_items to anon, authenticated;
grant insert, update, delete on public.user_lists, public.user_list_items to authenticated;
grant select, insert, update, delete on public.user_library_entries, public.watch_progress to authenticated;
grant select, insert on public.content_reports to authenticated;
grant all privileges on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

revoke all on function public.cinema_valid_code_array(text[], text) from public, anon, authenticated;
revoke all on function public.cinema_set_updated_at() from public, anon, authenticated;
revoke all on function public.cinema_check_asset_rights() from public, anon, authenticated;
revoke all on function public.cinema_check_destination_host() from public, anon, authenticated;
revoke all on function public.cinema_check_series_title() from public, anon, authenticated;
revoke all on function public.cinema_check_episode_title() from public, anon, authenticated;

commit;
),
  label text check (label is null or length(label) <= 100),
  priority smallint not null default 100 check (priority between 0 and 1000),
  destination_status text not null default 'pending_review' check (destination_status in ('pending_review', 'active', 'disabled', 'removed')),
  created_at timestamptz not null default now(),
  unique (asset_id, destination_url)
);

-- Exact hostname match only. Redirects and nested HLS playlists still require runtime validation.
create or replace function public.cinema_check_destination_host()
returns trigger language plpgsql set search_path = public as $$
declare
  asset_provider_id uuid;
  host_allowed boolean;
begin
  select provider_id into asset_provider_id from public.media_assets where id = new.asset_id;
  if asset_provider_id is null then
    raise exception 'media asset not found' using errcode = '23503';
  end if;
  select exists (
    select 1 from public.providers p
    where p.id = asset_provider_id and lower(new.destination_host) = any(p.allowed_hosts)
  ) into host_allowed;
  if not host_allowed then
    raise exception 'destination host is not allowlisted for this provider' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger media_destinations_host_guard
before insert or update of asset_id, destination_url, destination_host
on public.media_destinations for each row execute function public.cinema_check_destination_host();

create table public.subtitle_tracks (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  language_code text not null check (language_code ~ '^[a-z]{2,3}(-[A-Z]{2})?$'),
  format text not null check (format in ('vtt', 'srt', 'ttml', 'imsc')),
  is_forced boolean not null default false,
  is_sdh boolean not null default false,
  track_status text not null default 'pending_review' check (track_status in ('pending_review', 'active', 'disabled', 'removed')),
  attribution text check (attribution is null or length(attribution) <= 500),
  created_at timestamptz not null default now(),
  unique (asset_id, language_code, format, is_forced, is_sdh)
);

create table public.provider_health (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers(id) on delete cascade,
  territory text not null check (territory ~ '^[A-Z]{2}$'),
  checked_at timestamptz not null default now(),
  latency_ms integer check (latency_ms is null or latency_ms >= 0),
  health_state text not null check (health_state in ('healthy', 'degraded', 'unavailable', 'unknown')),
  failure_class text check (failure_class is null or length(failure_class) <= 120),
  unique (provider_id, territory, checked_at)
);
create index provider_health_latest_idx on public.provider_health (provider_id, territory, checked_at desc);

create table public.user_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 100),
  description text check (description is null or length(description) <= 500),
  visibility text not null default 'private' check (visibility in ('private', 'unlisted', 'public')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);
create index user_lists_owner_updated_idx on public.user_lists (user_id, updated_at desc);

create table public.user_list_items (
  list_id uuid not null references public.user_lists(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  position integer not null default 0 check (position >= 0),
  note text check (note is null or length(note) <= 500),
  created_at timestamptz not null default now(),
  primary key (list_id, title_id)
);

create table public.user_library_entries (
  user_id uuid not null references auth.users(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  entry_type text not null check (entry_type in ('watchlist', 'favorite', 'watched')),
  created_at timestamptz not null default now(),
  primary key (user_id, title_id, entry_type)
);
create index user_library_entries_user_type_idx on public.user_library_entries (user_id, entry_type, created_at desc);

create table public.watch_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  asset_id uuid not null references public.media_assets(id) on delete cascade,
  position_ms bigint not null default 0 check (position_ms >= 0),
  duration_ms bigint check (duration_ms is null or duration_ms > 0),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, asset_id),
  check (duration_ms is null or position_ms <= duration_ms + 30000)
);
create index watch_progress_user_updated_idx on public.watch_progress (user_id, updated_at desc);

create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete restrict,
  title_id uuid references public.titles(id) on delete set null,
  provider_id uuid references public.providers(id) on delete set null,
  territory text check (territory is null or territory ~ '^[A-Z]{2}$'),
  report_type text not null check (report_type in ('rights', 'incorrect_metadata', 'broken_source', 'subtitle', 'accessibility', 'safety', 'other')),
  description text not null check (length(trim(description)) between 10 and 4000),
  report_status text not null default 'submitted' check (report_status in ('submitted', 'triaged', 'investigating', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table public.rights_audit_log (
  id bigint generated always as identity primary key,
  actor_id text not null,
  action text not null check (length(action) between 1 and 120),
  object_type text not null check (length(object_type) between 1 and 80),
  object_id text not null,
  change_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index rights_audit_log_object_idx on public.rights_audit_log (object_type, object_id, created_at desc);

create trigger titles_set_updated_at before update on public.titles for each row execute function public.cinema_set_updated_at();
create trigger providers_set_updated_at before update on public.providers for each row execute function public.cinema_set_updated_at();
create trigger rights_grants_set_updated_at before update on public.rights_grants for each row execute function public.cinema_set_updated_at();
create trigger media_assets_set_updated_at before update on public.media_assets for each row execute function public.cinema_set_updated_at();
create trigger user_lists_set_updated_at before update on public.user_lists for each row execute function public.cinema_set_updated_at();
create trigger watch_progress_set_updated_at before update on public.watch_progress for each row execute function public.cinema_set_updated_at();

alter table public.titles enable row level security;
create policy titles_published_read on public.titles for select to anon, authenticated using (catalog_status = 'published');

alter table public.title_external_ids enable row level security;
alter table public.providers enable row level security;
alter table public.rights_grants enable row level security;
alter table public.media_assets enable row level security;
alter table public.media_destinations enable row level security;
alter table public.subtitle_tracks enable row level security;
alter table public.provider_health enable row level security;
alter table public.rights_audit_log enable row level security;
alter table public.content_reports enable row level security;

alter table public.user_lists enable row level security;
create policy user_lists_owner_all on public.user_lists for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.user_list_items enable row level security;
create policy user_list_items_owner_all on public.user_list_items for all to authenticated
using (exists (select 1 from public.user_lists l where l.id = list_id and l.user_id = auth.uid()))
with check (exists (select 1 from public.user_lists l where l.id = list_id and l.user_id = auth.uid()));

alter table public.user_library_entries enable row level security;
create policy user_library_entries_owner_all on public.user_library_entries for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.watch_progress enable row level security;
create policy watch_progress_owner_all on public.watch_progress for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy content_reports_insert_own on public.content_reports for insert to authenticated
with check (reporter_user_id = auth.uid());
create policy content_reports_read_own on public.content_reports for select to authenticated
using (reporter_user_id = auth.uid());

revoke all on all tables in schema public from anon, authenticated;
grant select on public.titles to anon, authenticated;
grant select, insert, update, delete on public.user_lists, public.user_list_items,
  public.user_library_entries, public.watch_progress to authenticated;
grant select, insert on public.content_reports to authenticated;
grant all privileges on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

revoke all on function public.cinema_valid_code_array(text[], text) from public, anon, authenticated;
revoke all on function public.cinema_set_updated_at() from public, anon, authenticated;
revoke all on function public.cinema_check_asset_rights() from public, anon, authenticated;
revoke all on function public.cinema_check_destination_host() from public, anon, authenticated;

commit;
