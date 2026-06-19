import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A snapshot of the user's whole hydration history. Achievements are
/// evaluated against this so the unlock rules live in one place.
class HydrationStats {
  const HydrationStats({
    required this.entryCount,
    required this.lifetimeMl,
    required this.bestStreak,
    required this.daysGoalMet,
  });

  final int entryCount; // total drinks ever logged
  final int lifetimeMl; // total millilitres ever logged
  final int bestStreak; // longest run of consecutive goal-met days
  final int daysGoalMet; // distinct days the daily goal was reached

  static const empty = HydrationStats(
    entryCount: 0,
    lifetimeMl: 0,
    bestStreak: 0,
    daysGoalMet: 0,
  );
}

/// A single unlockable badge. [valueOf] pulls the relevant number out of the
/// stats snapshot and [target] is the threshold to unlock.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
    required this.valueOf,
    this.unit = '',
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
  final String unit;
  final int Function(HydrationStats) valueOf;

  int current(HydrationStats s) => valueOf(s).clamp(0, target);
  bool isUnlocked(HydrationStats s) => valueOf(s) >= target;
  double progress(HydrationStats s) => (valueOf(s) / target).clamp(0.0, 1.0);
}

/// The full badge catalogue, ordered roughly from easiest to hardest.
final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_sip',
    title: 'First Sip',
    description: 'Log your very first drink.',
    icon: Icons.water_drop_rounded,
    color: AppColors.turquoise,
    target: 1,
    valueOf: (s) => s.entryCount,
  ),
  Achievement(
    id: 'goal_crusher',
    title: 'Goal Crusher',
    description: 'Reach your daily goal once.',
    icon: Icons.flag_rounded,
    color: AppColors.secondaryAccent,
    target: 1,
    valueOf: (s) => s.daysGoalMet,
  ),
  Achievement(
    id: 'making_waves',
    title: 'Making Waves',
    description: 'Log 10 drinks in total.',
    icon: Icons.waves_rounded,
    color: AppColors.primaryContainer,
    target: 10,
    valueOf: (s) => s.entryCount,
  ),
  Achievement(
    id: 'three_day_tide',
    title: '3-Day Tide',
    description: 'Hit your goal 3 days in a row.',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.hibiscus,
    target: 3,
    valueOf: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'weekly_wave',
    title: 'Weekly Wave',
    description: 'Hit your goal 7 days in a row.',
    icon: Icons.calendar_month_rounded,
    color: AppColors.primary,
    target: 7,
    valueOf: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'hydration_hero',
    title: 'Hydration Hero',
    description: 'Drink 25 litres all-time.',
    icon: Icons.emoji_events_rounded,
    color: AppColors.secondaryAccent,
    target: 25,
    unit: 'L',
    valueOf: (s) => s.lifetimeMl ~/ 1000,
  ),
];
