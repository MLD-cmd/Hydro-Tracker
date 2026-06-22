# HydroTracker 🌴💧

A friendly, island-themed hydration tracker built with Flutter. Log every
sip, keep a streak going, earn badges, and let your daily goal adapt to the
weather — all stored locally on your device, no account required.

Meet **Splash**, your hydration buddy, who cheers you on and gently nudges you
back to water when the less-hydrating drinks start to pile up.

## Features

- **Quick logging** — log Water, Coconut, Juice, Tea or Coffee in any amount,
  with a stepper, real-world sizes (250/330/500/750/1000 ml), or a typed value.
- **Hydration weighting** — each drink counts toward your goal by how much it
  actually hydrates (water 1.0, coconut 1.1, juice 0.85, tea 0.9, coffee 0.6).
- **Today's Mix** — per-drink bars showing how much of each drink you've had
  today (ml as the hero number) and its share of the day's mix.
- **Hydration Buddy** — an animated mascot whose mood tracks your progress and
  who nudges toward water when coffee/juice out-pour it.
- **Smart Goal with live weather** — fetches the live temperature for a chosen
  Philippine city (via Open-Meteo) and raises your goal on hot days, with an
  offline estimate as fallback and a weather-appropriate drink suggestion.
- **Stats — "Hydration Tides"** — Today / Week / Month views with a goal line,
  tappable day details, a timeline of when you drank, streaks, a personal best,
  achievements, and a rotating hydration tip.
- **Celebrations** — a confetti moment when you hit your goal or unlock a badge.
- **Reminders** — local hydration reminders with Island Quiet Hours.
- **Personalization** — editable profile (name + photo), three environment
  themes, and a one-time onboarding intro.
- **History** — a full, day-grouped log of every drink, with delete.

> No backend: all hydration data and settings are persisted on-device with
> `shared_preferences`. Profile photos are stored in the app documents folder.

## Tech stack

- **Flutter** (Material 3)
- **shared_preferences** — local persistence of entries and settings
- **http** — live weather from the free [Open-Meteo](https://open-meteo.com) API
- **flutter_local_notifications** — hydration reminders
- **image_picker** + **path_provider** — profile photo selection and storage

## Getting started

```bash
flutter pub get
flutter run
```

Requires the Flutter SDK. The live-weather feature needs internet access
(Android already declares the `INTERNET` permission); without it, the app falls
back to an offline temperature estimate.

## Project structure

```
lib/
├── main.dart                  # entry point → splash screen
├── models/                    # app settings, drink types, entries, achievements
├── screens/                   # splash, onboarding, sign in/up, dashboard, stats,
│                              # settings, history
├── services/                  # hydration repo, settings repo, weather, notifications
├── state/                     # environment theme
├── theme/                     # colors + text styles
└── widgets/                   # buddy, water circle, celebration overlay, cards, etc.
```

## Roadmap

Planned future work includes Supabase auth + cloud sync, a calendar view, an
hourly intake chart, editable log entries, custom drink types, and Filipino
localization.
