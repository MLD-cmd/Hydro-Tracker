/// How active the user is, used to personalise their daily hydration goal.
/// [key] is the stable string persisted locally and in Supabase (never the
/// enum index, so reordering the enum can't corrupt saved data).
enum ActivityLevel {
  sedentary(key: 'sedentary', label: 'Sedentary', extraMl: 0),
  light(key: 'light', label: 'Lightly active', extraMl: 350),
  active(key: 'active', label: 'Active', extraMl: 700),
  athlete(key: 'athlete', label: 'Athlete', extraMl: 1000);

  const ActivityLevel({
    required this.key,
    required this.label,
    required this.extraMl,
  });

  final String key;
  final String label;

  /// Millilitres added to the weight-based baseline for this activity level.
  final int extraMl;
}

/// Resolves a stored [key] back to its level, defaulting to [sedentary] for
/// null/unknown values (legacy rows, corrupt cache).
ActivityLevel activityLevelFromKey(String? key) {
  for (final level in ActivityLevel.values) {
    if (level.key == key) return level;
  }
  return ActivityLevel.sedentary;
}
