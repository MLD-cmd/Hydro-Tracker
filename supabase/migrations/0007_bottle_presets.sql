-- User-defined quick-log presets ("Nalgene / 600ml"). Built-in presets stay
-- client-side constants; this table only holds the custom ones a user creates.
-- Mirrors BottlePreset (lib/models/bottle_preset.dart): label, amount, icon key.
create table public.bottle_presets (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        not null references auth.users (id) on delete cascade,
  label      text        not null,
  amount_ml  integer     not null check (amount_ml > 0 and amount_ml <= 5000),
  icon_key   text        not null default 'local_drink',
  created_at timestamptz not null default now()
);

create index bottle_presets_user_idx on public.bottle_presets (user_id);

alter table public.bottle_presets enable row level security;

create policy "Bottle presets are viewable by their owner"
  on public.bottle_presets for select
  using ( (select auth.uid()) = user_id );

create policy "Bottle presets are insertable by their owner"
  on public.bottle_presets for insert
  with check ( (select auth.uid()) = user_id );

create policy "Bottle presets are updatable by their owner"
  on public.bottle_presets for update
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy "Bottle presets are deletable by their owner"
  on public.bottle_presets for delete
  using ( (select auth.uid()) = user_id );
