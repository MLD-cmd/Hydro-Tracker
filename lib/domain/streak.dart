/// The live state of the user's daily-goal streak. Unlike a naive count, this
/// keeps yesterday's run visible through today *until the day ends* — so a
/// streak doesn't read as "0 days" every morning before the first drink.
class StreakStatus {
  const StreakStatus({required this.count, required this.metToday});

  /// Consecutive goal-met days. Today is only counted once today's goal is met;
  /// otherwise the count reflects the run through yesterday.
  final int count;

  /// Whether today's goal has already been reached.
  final bool metToday;

  /// True when there's a live run on the board.
  bool get isActive => count > 0;

  /// True when a streak is riding on today but today isn't met yet — the
  /// "log something today or you'll break it" state.
  bool get atRisk => isActive && !metToday;

  static const none = StreakStatus(count: 0, metToday: false);
}

/// Computes the streak ending today. [totalForDay] returns the hydration-
/// weighted millilitres for a given day; [today] is the reference date.
///
/// If today's goal is met, today is included in the count. If not, the count
/// reflects the run through *yesterday* (today is still in progress), so the
/// streak survives the morning instead of resetting to zero before the first
/// drink is logged.
StreakStatus computeStreak({
  required int goalMl,
  required DateTime today,
  required int Function(DateTime day) totalForDay,
}) {
  if (goalMl <= 0) return StreakStatus.none;
  final t0 = DateTime(today.year, today.month, today.day);
  final metToday = totalForDay(t0) >= goalMl;
  var count = 0;
  // Start at today when it's already met, otherwise from yesterday.
  for (var i = metToday ? 0 : 1; ; i++) {
    final day = t0.subtract(Duration(days: i));
    if (totalForDay(day) >= goalMl) {
      count++;
    } else {
      break;
    }
  }
  return StreakStatus(count: count, metToday: metToday);
}
