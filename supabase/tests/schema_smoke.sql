-- Smoke/integration checks for the Cinema Supabase migration.
-- Run as a database administrator after applying the core migration.

begin;

insert into auth.users (id) values
  ('11111111-1111-4111-8111-111111111111'),
  ('22222222-2222-4222-8222-222222222222')
on conflict (id) do nothing;

insert into public.titles (id, canonical_title, title_type, release_year, catalog_status)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Cinema public fixture', 'movie', 2026, 'published'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Cinema private fixture', 'movie', 2026, 'draft'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'Cinema series fixture', 'series', 2026, 'draft'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'Cinema episode fixture', 'episode', 2026, 'draft')
on conflict (id) do nothing;

insert into public.seasons (id, series_title_id, season_number, season_name)
values ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 1, 'Season 1')
on conflict (id) do nothing;

insert into public.episodes (id, season_id, episode_number, episode_title_id, duration_ms)
values ('ffffffff-ffff-4fff-8fff-ffffffffffff', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 1, 'dddddddd-dddd-4ddd-8ddd-dddddddddddd', 1800000)
on conflict (id) do nothing;

insert into public.providers (id, provider_key, display_name, homepage_url, terms_url, allowed_hosts, provider_status)
values (
  '99999999-9999-4999-8999-999999999999',
  'cinema-ci-fixture',
  'Cinema CI Fixture Provider',
  'https://provider.example.org',
  'https://provider.example.org/terms',
  array['provider.example.org', 'media.example.org'],
  'active'
)
on conflict (id) do nothing;

insert into public.rights_grants (
  id, title_id, provider_id, licensor, evidence_url, license_reference,
  grant_status, valid_from, valid_until, territories, permitted_methods,
  reviewer_id, reviewed_at
)
values (
  '88888888-8888-4888-8888-888888888888',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '99999999-9999-4999-8999-999999999999',
  'Fictional rights holder for CI only',
  'https://rights.example.org/ci-fixture',
  'CI-TEST-ONLY-NOT-A-REAL-LICENSE',
  'approved',
  now() - interval '1 day',
  now() + interval '30 days',
  array['US', 'GB'],
  array['official_embed'],
  'ci-test-reviewer',
  now()
)
on conflict (id) do nothing;

insert into public.media_assets (id, title_id, provider_id, rights_grant_id, playback_method, asset_status)
values (
  '77777777-7777-4777-8777-777777777777',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  '99999999-9999-4999-8999-999999999999',
  '88888888-8888-4888-8888-888888888888',
  'official_embed',
  'active'
)
on conflict (id) do nothing;

insert into public.media_destinations (asset_id, destination_url, destination_host, label, destination_status)
values (
  '77777777-7777-4777-8777-777777777777',
  'https://media.example.org/fixture/embed',
  'media.example.org',
  'Non-playable CI fixture',
  'active'
)
on conflict (asset_id, destination_url) do nothing;

insert into public.user_lists (id, user_id, name, visibility)
values
  ('66666666-6666-4666-8666-666666666661', '11111111-1111-4111-8111-111111111111', 'User A private', 'private'),
  ('66666666-6666-4666-8666-666666666662', '22222222-2222-4222-8222-222222222222', 'User B private', 'private'),
  ('66666666-6666-4666-8666-666666666663', '22222222-2222-4222-8222-222222222222', 'User B shared', 'public')
on conflict (id) do nothing;

insert into public.user_list_items (list_id, title_id, position)
values
  ('66666666-6666-4666-8666-666666666662', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 0),
  ('66666666-6666-4666-8666-666666666663', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 0)
on conflict (list_id, title_id) do nothing;

-- Rights checks: unsupported methods and mismatched URL hosts must be rejected.
do $$
begin
  begin
    insert into public.media_assets (title_id, provider_id, rights_grant_id, playback_method)
    values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      '99999999-9999-4999-8999-999999999999',
      '88888888-8888-4888-8888-888888888888',
      'direct_playback'
    );
    raise exception 'unsupported playback method was accepted';
  exception when check_violation then
    null;
  end;

  begin
    insert into public.media_destinations (asset_id, destination_url, destination_host)
    values (
      '77777777-7777-4777-8777-777777777777',
      'https://attacker.example.net/stream',
      'media.example.org'
    );
    raise exception 'mismatched destination host was accepted';
  exception when check_violation then
    null;
  end;
end;
$$;

-- Anonymous users see published metadata only.
set local role anon;
do $$
begin
  if (select count(*) from public.titles) <> 1 then
    raise exception 'anonymous catalogue policy exposed the wrong number of titles';
  end if;
end;
$$;
reset role;

-- User A sees own private data and explicitly shared lists, never User B's private data.
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);

do $$
declare
  list_count integer;
  item_count integer;
begin
  select count(*) into list_count from public.user_lists;
  if list_count <> 2 then
    raise exception 'user list RLS failed: expected 2 visible lists, got %', list_count;
  end if;

  select count(*) into item_count from public.user_list_items;
  if item_count <> 1 then
    raise exception 'shared list item RLS failed: expected 1 visible item, got %', item_count;
  end if;
end;
$$;

insert into public.user_library_entries (user_id, title_id, entry_type)
values ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'watchlist');

insert into public.watch_progress (user_id, asset_id, position_ms, duration_ms)
values ('11111111-1111-4111-8111-111111111111', '77777777-7777-4777-8777-777777777777', 120000, 1800000);

insert into public.content_reports (reporter_user_id, title_id, report_type, description)
values ('11111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'incorrect_metadata', 'CI-only test report for RLS policy coverage.');

do $$
begin
  begin
    insert into public.user_library_entries (user_id, title_id, entry_type)
    values ('22222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'watchlist');
    raise exception 'cross-user library insert was accepted';
  exception when insufficient_privilege then
    null;
  end;

  if (select count(*) from public.content_reports) <> 1 then
    raise exception 'report ownership policy did not return the reporter own report';
  end if;

  if (select count(*) from public.watch_progress) <> 1 then
    raise exception 'user progress write/read policy failed';
  end if;
end;
$$;

reset role;
rollback;
