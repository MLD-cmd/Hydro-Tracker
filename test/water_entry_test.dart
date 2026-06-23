import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/water_entry.dart';

void main() {
  test('copyWith can change amount, type and timestamp', () {
    final t = DateTime(2026, 1, 1, 8);
    final e = WaterEntry(amountMl: 250, timestamp: t, type: 'Water', id: 'x');
    final edited = e.copyWith(
      amountMl: 500,
      type: 'Coffee',
      timestamp: DateTime(2026, 1, 1, 9),
    );
    expect(edited.amountMl, 500);
    expect(edited.type, 'Coffee');
    expect(edited.timestamp, DateTime(2026, 1, 1, 9));
    expect(edited.id, 'x'); // id preserved
  });

  test('deletedAt round-trips through JSON and marks isDeleted', () {
    final e = WaterEntry(
      amountMl: 250,
      timestamp: DateTime(2026, 1, 1),
      id: 'x',
      deletedAt: DateTime(2026, 1, 2),
    );
    expect(e.isDeleted, isTrue);
    final restored = WaterEntry.fromJson(e.toJson());
    expect(restored.isDeleted, isTrue);
    expect(restored.deletedAt, DateTime(2026, 1, 2));
  });

  test('a fresh entry is not deleted', () {
    final e = WaterEntry(amountMl: 250, timestamp: DateTime(2026, 1, 1));
    expect(e.isDeleted, isFalse);
  });
}
