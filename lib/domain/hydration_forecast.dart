/// How today's intake compares to an even-paced plan across the active day.
enum PaceStatus {
  /// Before the active window has really begun, or nothing logged to project
  /// from yet.
  notStarted,

  /// Behind where an even pace would put you by now.
  behind,

  /// Roughly on the even-paced line.
  onTrack,

  /// Ahead of the even-paced line.
  ahead,

  /// Goal already reached.
  met,
}

/// A read-only projection of the day's hydration: how you're pacing against an
/// even spread of the goal across your active hours, and when you'll reach the
/// goal if you keep up the current rate.
class HydrationForecast {
  const HydrationForecast({
    required this.status,
    required this.remainingMl,
    required this.paceDeltaMl,
    this.projectedFinish,
  });

  final PaceStatus status;

  /// Millilitres still needed to reach the goal (0 once met).
  final int remainingMl;

  /// Signed gap to the even-paced target for *now*: positive when ahead of the
  /// line, negative when behind it.
  final int paceDeltaMl;

  /// When the goal is projected to be reached at the current rate, or null when
  /// it can't be projected (nothing logged, before the window, or already met).
  final DateTime? projectedFinish;

  static const empty = HydrationForecast(
    status: PaceStatus.notStarted,
    remainingMl: 0,
    paceDeltaMl: 0,
  );
}

/// Projects today's hydration against an even pace from [dayStartHour] to
/// [dayEndHour] (the user's active window). [now] is the reference time.
HydrationForecast forecastHydration({
  required int currentMl,
  required int goalMl,
  required DateTime now,
  int dayStartHour = 8,
  int dayEndHour = 20,
}) {
  if (goalMl <= 0) return HydrationForecast.empty;

  final remaining = currentMl >= goalMl ? 0 : goalMl - currentMl;

  if (remaining == 0) {
    return HydrationForecast(
      status: PaceStatus.met,
      remainingMl: 0,
      paceDeltaMl: currentMl - goalMl, // >= 0
    );
  }

  final windowStart = DateTime(now.year, now.month, now.day, dayStartHour);
  final windowEnd = DateTime(now.year, now.month, now.day, dayEndHour);
  final totalMinutes = windowEnd.difference(windowStart).inMinutes;

  // Degenerate window (end <= start) — there's no line to pace against, so just
  // report what's left.
  if (totalMinutes <= 0) {
    return HydrationForecast(
      status: currentMl > 0 ? PaceStatus.onTrack : PaceStatus.notStarted,
      remainingMl: remaining,
      paceDeltaMl: 0,
    );
  }

  final elapsedMinutes =
      now.difference(windowStart).inMinutes.clamp(0, totalMinutes);
  final elapsedFraction = elapsedMinutes / totalMinutes;
  final expectedByNow = (goalMl * elapsedFraction).round();
  final paceDelta = currentMl - expectedByNow;

  // Before the window starts, or nothing logged — no rate to extrapolate from.
  if (currentMl <= 0 || elapsedMinutes <= 0) {
    return HydrationForecast(
      status: PaceStatus.notStarted,
      remainingMl: remaining,
      paceDeltaMl: paceDelta,
    );
  }

  // Project the finish from the rate achieved so far (ml per minute).
  final ratePerMinute = currentMl / elapsedMinutes;
  final minutesToGoal = (remaining / ratePerMinute).ceil();
  final projectedFinish = now.add(Duration(minutes: minutesToGoal));

  // A tolerance band around the even-paced line still counts as "on track", so
  // small wobbles don't flip the label back and forth.
  final tolerance = (goalMl * 0.05).round();
  final PaceStatus status;
  if (paceDelta > tolerance) {
    status = PaceStatus.ahead;
  } else if (paceDelta < -tolerance) {
    status = PaceStatus.behind;
  } else {
    status = PaceStatus.onTrack;
  }

  return HydrationForecast(
    status: status,
    remainingMl: remaining,
    paceDeltaMl: paceDelta,
    projectedFinish: projectedFinish,
  );
}
