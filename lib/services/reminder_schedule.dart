/// The list of whole-hour times (0–23) at which to fire hydration reminders,
/// generated from a [startHour]/[endHour] window at [intervalHours] spacing.
/// When [quietHours] is on the window is clamped to 9..18 so reminders avoid
/// early mornings and late evenings. Always returns at least the start hour.
List<int> reminderHours({
  required int startHour,
  required int endHour,
  required int intervalHours,
  bool quietHours = false,
}) {
  var start = startHour;
  var end = endHour;
  if (quietHours) {
    start = start < 9 ? 9 : start;
    end = end > 18 ? 18 : end;
  }
  if (end < start) return [start];
  final step = intervalHours < 1 ? null : intervalHours;
  if (step == null) return [start];

  final hours = <int>[];
  for (var h = start; h <= end; h += step) {
    hours.add(h);
  }
  return hours;
}
