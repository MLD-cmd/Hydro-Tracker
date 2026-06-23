-- Customisable reminder window + spacing on the profile. Mirrors the new
-- AppSettings reminder fields (lib/models/app_settings.dart).
alter table public.profiles
  add column if not exists reminder_start_hour     smallint not null default 8,
  add column if not exists reminder_end_hour       smallint not null default 20,
  add column if not exists reminder_interval_hours smallint not null default 2;
