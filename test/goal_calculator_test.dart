import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/activity_level.dart';
import 'package:hydro_tracker/services/goal_calculator.dart';

void main() {
  test('baseline is ~35 ml per kg, rounded to nearest 50', () {
    // 70 kg * 35 = 2450 -> already a multiple of 50.
    expect(
      recommendedGoalMl(weightKg: 70, activity: ActivityLevel.sedentary),
      2450,
    );
  });

  test('activity level adds its extra millilitres', () {
    // 70*35 = 2450 + 700 (active) = 3150.
    expect(
      recommendedGoalMl(weightKg: 70, activity: ActivityLevel.active),
      3150,
    );
  });

  test('result is clamped to the sane 1500..4500 range', () {
    expect(
      recommendedGoalMl(weightKg: 30, activity: ActivityLevel.sedentary),
      1500, // 30*35 = 1050 -> clamped up
    );
    expect(
      recommendedGoalMl(weightKg: 200, activity: ActivityLevel.athlete),
      4500, // 200*35 + 1000 = 8000 -> clamped down
    );
  });

  test('rounds to the nearest 50 ml', () {
    // 63 kg * 35 = 2205 -> nearest 50 is 2200.
    expect(
      recommendedGoalMl(weightKg: 63, activity: ActivityLevel.sedentary),
      2200,
    );
  });
}
