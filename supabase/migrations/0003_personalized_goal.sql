-- Personalised goal inputs on the profile. Mirrors the new AppSettings fields
-- weightKg (lib/models/app_settings.dart) and activityLevel
-- (lib/models/activity_level.dart, stored as its stable string key).
alter table public.profiles
  add column if not exists weight_kg      numeric,
  add column if not exists activity_level text not null default 'sedentary';
