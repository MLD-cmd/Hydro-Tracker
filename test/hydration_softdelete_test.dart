import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydro_tracker/models/water_entry.dart';
import 'package:hydro_tracker/repositories/entry_repository.dart';
import 'package:hydro_tracker/repositories/hydration_repository.dart';

/// Remote whose delete fails (simulating offline), and which on fetch returns a
/// row the client already tombstoned — the classic resurrection scenario.
class _OfflineDeleteRemote extends EntryRepository {
  final List<WaterEntry> serverRows;
  _OfflineDeleteRemote(this.serverRows);

  @override
  Future<bool> delete(String id) async => false; // offline
  @override
  Future<List<WaterEntry>?> fetchAll() async => serverRows;
  @override
  Future<List<WaterEntry>?> insertAll(List<WaterEntry> e) async => [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a tombstoned entry is excluded from totals', () async {
    final repo = HydrationRepository(remote: _OfflineDeleteRemote([]));
    final e = WaterEntry(
      amountMl: 500,
      timestamp: DateTime.now(),
      id: 'a',
    );
    repo.seedForTest([e]);
    await repo.deleteEntry(e);
    expect(repo.todayTotal, 0);
    expect(repo.entries.where((x) => !x.isDeleted), isEmpty);
  });

  test('offline-deleted row does not resurrect on load', () async {
    final e = WaterEntry(amountMl: 500, timestamp: DateTime.now(), id: 'a');
    // The server still has the row (delete never reached it). The local cache
    // holds the tombstone.
    final repo = HydrationRepository(remote: _OfflineDeleteRemote([e]));
    repo.seedForTest([e.copyWith(deletedAt: DateTime.now())]);
    await repo.persistForTest();

    await repo.load();

    // Even though the server returned the row, the local tombstone wins.
    expect(repo.todayTotal, 0);
  });
}
