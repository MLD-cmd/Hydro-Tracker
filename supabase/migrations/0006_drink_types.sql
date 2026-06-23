-- User-defined drink types. Built-in drinks stay client-side constants; this
-- table only holds the custom ones a user creates. Mirrors DrinkType.custom
-- (lib/models/drink_type.dart): name, hydration weight, icon key, hex colour.
create table public.drink_types (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        not null references auth.users (id) on delete cascade,
  name       text        not null,
  hydration  numeric     not null default 1.0 check (hydration >= 0 and hydration <= 2),
  icon_key   text        not null default 'local_drink',
  color_hex  text        not null default '4FC3F7',
  created_at timestamptz not null default now()
);

create index drink_types_user_idx on public.drink_types (user_id);

alter table public.drink_types enable row level security;

create policy "Drink types are viewable by their owner"
  on public.drink_types for select
  using ( (select auth.uid()) = user_id );

create policy "Drink types are insertable by their owner"
  on public.drink_types for insert
  with check ( (select auth.uid()) = user_id );

create policy "Drink types are updatable by their owner"
  on public.drink_types for update
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create policy "Drink types are deletable by their owner"
  on public.drink_types for delete
  using ( (select auth.uid()) = user_id );
