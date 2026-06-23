-- Soft-delete for logged drinks: instead of removing a row, stamp deleted_at.
-- Reads filter these out; this makes an offline delete durable (a hard DELETE
-- that failed offline used to resurrect on the next sync).
alter table public.water_entries
  add column if not exists deleted_at timestamptz;

-- Hot reads only ever want live rows, so index the common predicate.
create index if not exists water_entries_live_idx
  on public.water_entries (user_id, logged_at desc)
  where deleted_at is null;
