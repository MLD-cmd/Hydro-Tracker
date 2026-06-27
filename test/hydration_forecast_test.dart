import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/domain/hydration_forecast.dart';

void main() {
  // Noon, inside an 8:00–20:00 window: a third of the day has elapsed.
  final noon = DateTime(2026, 6, 24, 12);

  test('a met goal reports met with nothing remaining', () {
    final f = forecastHydration(
      currentMl: 3000,
      goalMl: 3000,
      now: noon,
    );
    expect(f.status, PaceStatus.met);
    expect(f.remainingMl, 0);
    expect(f.projectedFinish, isNull);
  });

  test('nothing logged yet is notStarted with no projection', () {
    final f = forecastHydration(
      currentMl: 0,
      goalMl: 3000,
      now: noon,
    );
    expect(f.status, PaceStatus.notStarted);
    expect(f.remainingMl, 3000);
    expect(f.projectedFinish, isNull);
  });

  test('at the even-paced amount is onTrack', () {
    // By noon (1/3 of 8–20) an even pace expects goal/3 = 1000ml.
    final f = forecastHydration(
      currentMl: 1000,
      goalMl: 3000,
      now: noon,
    );
    expect(f.status, PaceStatus.onTrack);
    expect(f.paceDeltaMl, 0);
    // 1000ml in 4h → 250ml/h; 2000ml left → finishes 8h later, at 20:00.
    expect(f.projectedFinish, DateTime(2026, 6, 24, 20));
  });

  test('well above the line is ahead', () {
    final f = forecastHydration(
      currentMl: 2000,
      goalMl: 3000,
      now: noon,
    );
    expect(f.status, PaceStatus.ahead);
    expect(f.paceDeltaMl, 1000); // 2000 logged vs 1000 expected
    expect(f.projectedFinish, isNotNull);
  });

  test('well below the line is behind', () {
    final f = forecastHydration(
      currentMl: 300,
      goalMl: 3000,
      now: noon,
    );
    expect(f.status, PaceStatus.behind);
    expect(f.paceDeltaMl, -700); // 300 logged vs 1000 expected
    expect(f.remainingMl, 2700);
  });

  test('a non-positive goal is empty', () {
    final f = forecastHydration(currentMl: 500, goalMl: 0, now: noon);
    expect(f.status, PaceStatus.notStarted);
    expect(f.remainingMl, 0);
  });
}
