import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/activity_level.dart';
import 'package:hydro_tracker/models/app_settings.dart';

void main() {
  test('weight + activity round-trip through JSON', () {
    const s = AppSettings(weightKg: 68.5, activityLevel: ActivityLevel.active);
    final restored = AppSettings.fromJson(s.toJson());
    expect(restored.weightKg, 68.5);
    expect(restored.activityLevel, ActivityLevel.active);
  });

  test('defaults: no weight, sedentary activity', () {
    const s = AppSettings();
    expect(s.weightKg, isNull);
    expect(s.activityLevel, ActivityLevel.sedentary);
  });

  test('copyWith updates weight + activity', () {
    const s = AppSettings();
    final next = s.copyWith(weightKg: 80, activityLevel: ActivityLevel.athlete);
    expect(next.weightKg, 80);
    expect(next.activityLevel, ActivityLevel.athlete);
  });

  test('reminder schedule round-trips with defaults', () {
    const s = AppSettings();
    final restored = AppSettings.fromJson(s.toJson());
    expect(restored.reminderStartHour, 8);
    expect(restored.reminderEndHour, 20);
    expect(restored.reminderIntervalHours, 2);
  });
}
