import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/services/reminder_schedule.dart';

void main() {
  test('generates hours from start to end at the interval', () {
    expect(
      reminderHours(startHour: 8, endHour: 20, intervalHours: 4),
      [8, 12, 16, 20],
    );
  });

  test('interval of 2 fills the day', () {
    expect(
      reminderHours(startHour: 8, endHour: 14, intervalHours: 2),
      [8, 10, 12, 14],
    );
  });

  test('quiet hours clamps the window to 9..18', () {
    expect(
      reminderHours(
        startHour: 6,
        endHour: 22,
        intervalHours: 3,
        quietHours: true,
      ),
      [9, 12, 15, 18],
    );
  });

  test('guards against bad input (end before start, zero interval)', () {
    expect(reminderHours(startHour: 20, endHour: 8, intervalHours: 2), [20]);
    expect(reminderHours(startHour: 8, endHour: 20, intervalHours: 0), [8]);
  });
}
