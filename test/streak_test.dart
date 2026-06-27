import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/domain/streak.dart';

void main() {
  // Builds a totalForDay lookup from a {daysAgo: ml} map (0 = today).
  int Function(DateTime) lookup(DateTime today, Map<int, int> byDaysAgo) {
    final t0 = DateTime(today.year, today.month, today.day);
    return (day) {
      final d = DateTime(day.year, day.month, day.day);
      final daysAgo = t0.difference(d).inDays;
      return byDaysAgo[daysAgo] ?? 0;
    };
  }

  final today = DateTime(2026, 6, 24, 10);

  test('counts today when today is met', () {
    final s = computeStreak(
      goalMl: 2000,
      today: today,
      totalForDay: lookup(today, {0: 2100, 1: 2200, 2: 2500}),
    );
    expect(s.count, 3);
    expect(s.metToday, isTrue);
    expect(s.atRisk, isFalse);
  });

  test('keeps yesterday\'s run alive when today is not met yet', () {
    final s = computeStreak(
      goalMl: 2000,
      today: today,
      totalForDay: lookup(today, {0: 500, 1: 2200, 2: 2500, 3: 2100}),
    );
    // Today (500) is below goal, but the run through yesterday is intact.
    expect(s.count, 3);
    expect(s.metToday, isFalse);
    expect(s.atRisk, isTrue);
  });

  test('a broken run (yesterday missed, today not met) is zero', () {
    final s = computeStreak(
      goalMl: 2000,
      today: today,
      totalForDay: lookup(today, {0: 100, 1: 0, 2: 2500}),
    );
    expect(s.count, 0);
    expect(s.isActive, isFalse);
  });

  test('today met after a missed yesterday starts a fresh 1-day streak', () {
    final s = computeStreak(
      goalMl: 2000,
      today: today,
      totalForDay: lookup(today, {0: 2100, 1: 0, 2: 2500}),
    );
    expect(s.count, 1);
    expect(s.metToday, isTrue);
  });

  test('a non-positive goal yields no streak', () {
    final s = computeStreak(
      goalMl: 0,
      today: today,
      totalForDay: lookup(today, {0: 2100, 1: 2200}),
    );
    expect(s.count, 0);
  });
}
