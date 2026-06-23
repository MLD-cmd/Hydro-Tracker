-- HydroTracker initial schema: per-user profile + logged drinks, with
-- Row-Level Security so each user can only ever touch their own rows.
--
-- Mirrors the app models:
--   profiles      <- AppSettings (lib/models/app_settings.dart)
--   water_entries <- WaterEntry  (lib/models/water_entry.dart)
-- effective_ml is intentionally NOT stored: it's derived client-side from the
-- drink type's hydration weight, so the raw amount + type are the source of
-- truth (matches WaterEntry.effectiveMl).

-- ---------------------------------------------------------------------------
-- profiles: one row per auth user, created automatically on sign-up (see the
-- handle_new_user trigger below). Mirrors AppSettings.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id                 uuid primary key references auth.users (id) on delete cascade,
  name               text        not null default 'Lilo Pelekai',
  base_goal_ml       integer     not null default 2500,
  smart_goal         boolean     not null default false,
  theme_index        smallint    not null default 0,   -- 0 Shoreline, 1 Lagoon, 2 Hibiscus
  reminders          boolean     not null default true,
  quiet_hours        boolean     not null default false,
  weather_city       text        not null default 'Manila',
  onboarded          boolean     not null default false,
  -- Cloud equivalent of AppSettings.profilePhotoPath (a local file path today);
  -- becomes a Supabase Storage URL once photo upload is wired.
  avatar_url         text,
  updated_at         timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- water_entries: every logged drink, owned by a user. Mirrors WaterEntry.
-- ---------------------------------------------------------------------------
create table public.water_entries (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users (id) on delete cascade,
  amount_ml   integer     not null check (amount_ml > 0),
  type        text        not null default 'Water',
  logged_at   timestamptz not null,                 -- WaterEntry.timestamp
  created_at  timestamptz not null default now()
);

-- The app's hot queries are "this user's entries, by time" (today total,
-- last-7/30 days, streaks, the calendar), so index on (user_id, logged_at).
create index water_entries_user_logged_at_idx
  on public.water_entries (user_id, logged_at desc);

-- ---------------------------------------------------------------------------
-- Row-Level Security: deny by default, then allow each user only their rows.
-- ---------------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.water_entries enable row level security;

-- profiles: a user sees / edits only their own profile (id == auth.uid()).
create policy "Profiles are viewable by their owner"
  on public.profiles for select
  using ( (select auth.uid()) = id );

create policy "Profiles are updatable by their owner"
  on public.profiles for update
  using ( (select auth.uid()) = id )
  with check ( (select auth.uid()) = id );

-- water_entries: full CRUD, but only on rows the user owns.
create policy "Entries are viewable by their owner"
  on public.water_entries for select
  using ( (select auth.uid()) = user_id );

create policy "Entries are insertable by their owner"
  on public.water_entries for insert
  with check ( (select auth.uid()) = user_id );

create policy "Entries are updatable by their owner"
  on public.water_entries for update
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy "Entries are deletable by their owner"
  on public.water_entries for delete
  using ( (select auth.uid()) = user_id );

-- ---------------------------------------------------------------------------
-- Auto-create a profile row whenever a new auth user signs up. Pulls the name
-- from the sign-up metadata (AuthService.signUp passes data: {'name': ...}).
-- SECURITY DEFINER + empty search_path is the Supabase-recommended hardening.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'name', ''), 'Lilo Pelekai')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep profiles.updated_at fresh on every change.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
