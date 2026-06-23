import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/activity_level.dart';

void main() {
  test('every level round-trips through its storage key', () {
    for (final level in ActivityLevel.values) {
      expect(activityLevelFromKey(level.key), level);
    }
  });

  test('unknown key falls back to sedentary', () {
    expect(activityLevelFromKey('nonsense'), ActivityLevel.sedentary);
    expect(activityLevelFromKey(null), ActivityLevel.sedentary);
  });

  test('labels are human-readable', () {
    expect(ActivityLevel.athlete.label, 'Athlete');
  });
}
