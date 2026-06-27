import '../models/activity_level.dart';

/// Millilitres of water per kilogram of body weight — the common rule-of-thumb
/// baseline (~35 ml/kg). Good enough for a personalised suggestion; the user can
/// always override the result with the goal stepper.
const double _mlPerKg = 35.0;

const int _minGoalMl = 1500;
const int _maxGoalMl = 4500;

/// A recommended daily goal for someone of [weightKg] at [activity], rounded to
/// the nearest 50 ml and clamped to a sensible range so a stray input can't
/// produce an absurd goal.
int recommendedGoalMl({
  required double weightKg,
  required ActivityLevel activity,
}) {
  final raw = weightKg * _mlPerKg + activity.extraMl;
  final rounded = (raw / 50).round() * 50;
  return rounded.clamp(_minGoalMl, _maxGoalMl);
}
