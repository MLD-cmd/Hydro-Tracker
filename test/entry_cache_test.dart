import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/domain/entry_cache.dart';
import 'package:hydro_tracker/models/water_entry.dart';

void main() {
  WaterEntry entry(int ml) =>
      WaterEntry(amountMl: ml, timestamp: DateTime(2026, 6, 24, 10), type: 'Water');

  test('appends to an empty/null cache, producing a one-item list', () {
    final raw = appendCachedEntry(null, entry(250));
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final restored = WaterEntry.fromJson(list.first as Map<String, dynamic>);
    expect(restored.amountMl, 250);
    expect(restored.type, 'Water');
    expect(restored.id, isNull); // local-only — synced up on next load()
  });

  test('appends to an existing cache without dropping prior entries', () {
    final first = appendCachedEntry(null, entry(250));
    final second = appendCachedEntry(first, entry(500));
    final list = jsonDecode(second) as List;
    expect(list.length, 2);
    expect((list[0] as Map)['amountMl'], 250);
    expect((list[1] as Map)['amountMl'], 500);
  });

  test('treats an empty string the same as null', () {
    final raw = appendCachedEntry('', entry(330));
    expect((jsonDecode(raw) as List).length, 1);
  });
}
