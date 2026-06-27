import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydro_tracker/models/water_entry.dart';
import 'package:hydro_tracker/repositories/entry_repository.dart';
import 'package:hydro_tracker/repositories/hydration_repository.dart';

/// A remote that never reaches the network — update always "succeeds" locally.
class _NoopRemote extends EntryRepository {
  @override
  Future<bool> update(WaterEntry entry) async => true;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('updateEntry replaces the matching entry in place', () async {
    final repo = HydrationRepository(remote: _NoopRemote());
    final original = WaterEntry(
      amountMl: 250,
      timestamp: DateTime.now(),
      type: 'Water',
      id: 'abc',
    );
    repo.seedForTest([original]);

    await repo.updateEntry(original, amountMl: 500, type: 'Coffee');

    final entries = repo.entries;
    expect(entries.length, 1);
    expect(entries.first.amountMl, 500);
    expect(entries.first.type, 'Coffee');
    expect(entries.first.id, 'abc');
  });
}
