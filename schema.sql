-- ============================================================
--  Family Meal Planner — Supabase schema
--  Run this whole file once in Supabase → SQL Editor → New query.
-- ============================================================
--  Security model (v1, family-scale):
--  Every row carries a `family_code` (a shared secret you choose).
--  The app sends that code on every request in an `x-family-code`
--  header, and the RLS policies below only let you see/edit rows
--  whose family_code matches the header you presented. So the
--  public anon key alone reveals nothing — you also need the code.
--  Pick a long, non-obvious family code (it's your household's key).
-- ============================================================

-- ---------- Tables ----------

create table if not exists families (
  code        text primary key,
  name        text not null,
  -- the protein / vegetable / starch option lists the family maintains
  components  jsonb not null default '{"protein":[],"vegetable":[],"starch":[]}',
  created_at  timestamptz not null default now()
);

create table if not exists members (
  id          uuid primary key default gen_random_uuid(),
  family_code text not null,
  name        text not null,
  -- free-form prefs: likes, dislikes, allergies, notes
  prefs       jsonb not null default '{"likes":[],"dislikes":[],"notes":""}',
  created_at  timestamptz not null default now()
);

create table if not exists recipes (
  id          uuid primary key default gen_random_uuid(),
  family_code text not null,
  title       text not null,
  protein     text default '',
  vegetable   text default '',
  starch      text default '',
  ingredients text default '',
  steps       text default '',
  tags        text[] default '{}',
  notes       text default '',
  source      text default '',        -- e.g. "HelloFresh-inspired", "Grandma's"
  created_by  text default '',
  created_at  timestamptz not null default now()
);

create table if not exists plan_entries (
  id          uuid primary key default gen_random_uuid(),
  family_code text not null,
  day         date not null,          -- the calendar date this dinner is for
  recipe_id   uuid,                   -- optional link to a saved recipe
  title       text not null,          -- snapshot title (works even if recipe deleted)
  notes       text default '',
  created_at  timestamptz not null default now(),
  unique (family_code, day)           -- one dinner per night; upsert to change it
);

create table if not exists proposals (
  id          uuid primary key default gen_random_uuid(),
  family_code text not null,
  week_of     date not null,          -- Monday of the week this is proposed for
  title       text not null,
  protein     text default '',
  vegetable   text default '',
  starch      text default '',
  description text default '',
  ingredients text default '',
  origin      text default 'local',   -- 'local' or 'ai'
  created_by  text default '',
  created_at  timestamptz not null default now()
);

create table if not exists votes (
  id           uuid primary key default gen_random_uuid(),
  family_code  text not null,
  proposal_id  uuid not null references proposals(id) on delete cascade,
  member_name  text not null,
  value        int not null default 1, -- +1 love it, -1 no thanks
  created_at   timestamptz not null default now(),
  unique (proposal_id, member_name)    -- one vote per person per proposal
);

-- ---------- Row Level Security ----------
-- Enable RLS, then allow access only when the request's x-family-code
-- header matches the row's family_code.

alter table families     enable row level security;
alter table members      enable row level security;
alter table recipes      enable row level security;
alter table plan_entries enable row level security;
alter table proposals    enable row level security;
alter table votes        enable row level security;

-- helper expression: the family code presented in the request header
--   (current_setting('request.headers', true)::json ->> 'x-family-code')

-- families: the code column IS the family_code
drop policy if exists fam_all on families;
create policy fam_all on families
  for all
  using  (code = (current_setting('request.headers', true)::json ->> 'x-family-code'))
  with check (code = (current_setting('request.headers', true)::json ->> 'x-family-code'));

-- generic policy for every child table keyed by family_code
drop policy if exists mem_all on members;
create policy mem_all on members
  for all
  using  (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'))
  with check (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'));

drop policy if exists rec_all on recipes;
create policy rec_all on recipes
  for all
  using  (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'))
  with check (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'));

drop policy if exists plan_all on plan_entries;
create policy plan_all on plan_entries
  for all
  using  (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'))
  with check (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'));

drop policy if exists prop_all on proposals;
create policy prop_all on proposals
  for all
  using  (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'))
  with check (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'));

drop policy if exists vote_all on votes;
create policy vote_all on votes
  for all
  using  (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'))
  with check (family_code = (current_setting('request.headers', true)::json ->> 'x-family-code'));

-- ---------- Realtime ----------
-- Broadcast row changes so every open device updates live.
alter publication supabase_realtime add table families;
alter publication supabase_realtime add table members;
alter publication supabase_realtime add table recipes;
alter publication supabase_realtime add table plan_entries;
alter publication supabase_realtime add table proposals;
alter publication supabase_realtime add table votes;

-- Done. Next: open the app, paste your Project URL + anon key,
-- and create your family with a code that matches what you'll share.
