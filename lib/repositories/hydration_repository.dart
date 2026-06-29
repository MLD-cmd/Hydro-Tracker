import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_entry.dart';
import '../models/achievement.dart';
import 'entry_repository.dart';
import '../domain/entry_cache.dart';
import '../domain/streak.dart';
import '../domain/drink_catalog.dart';

/// The hydration data store the UI talks to. Entries live in the Supabase
/// `water_entries` table (via [EntryRepository]); the in-memory [_entries] list
/// is the working copy every aggregation reads from, and SharedPreferences is a
/// read-cache so the app still shows data when offline.
///
/// This is online-writes / cached-reads: logging and deleting need a
/// connection, but reads fall back to the cache. Queue-and-sync offline writes
/// would be a later Drift/PowerSync step.
class HydrationRepository {
  // The cache key lives in domain/entry_cache.dart so the notification
  // background isolate writes to the same store (see [appendCachedEntry]).
  static const _entriesKey = kEntriesCacheKey;

  HydrationRepository({EntryRepository? remote})
      : _remote = remote ?? EntryRepository();

  final EntryRepository _remote;

  List<WaterEntry> _entries = [];

  List<WaterEntry> get entries => List.unmodifiable(_entries);

  /// Test-only: seed the in-memory list directly. Not used in production code.
  @visibleForTesting
  void seedForTest(List<WaterEntry> entries) => _entries = [...entries];

  /// Test-only: flush the in-memory list to the cache.
  @visibleForTesting
  Future<void> persistForTest() => _persist();

  /// Entries that haven't been soft-deleted — what every aggregation reads.
  List<WaterEntry> get _live => _entries.where((e) => !e.isDeleted).toList();

  /// Loads entries for the signed-in user. Prefers Supabase; on success it
  /// mirrors the rows to the cache. If the cloud is unreachable it falls back to
  /// the cache so reads keep working offline. Call once on startup / after login.
  Future<void> load() async {
    final cached = await _readCache();
    final remote = await _remote.fetchAll();

    if (remote == null) {
      // Signed out or offline — use whatever the cache has.
      _entries = cached;
      return;
    }

    // Retry any unsynced deletes: tombstones we hold locally whose rows the
    // server still returns (its delete never landed). Re-issue the soft-delete.
    final tombstoneIds = cached
        .where((e) => e.isDeleted && e.id != null)
        .map((e) => e.id!)
        .toSet();
    for (final id in tombstoneIds) {
      await _remote.delete(id);
    }

    // One-time migration: local-only entries (no id, not deleted) that predate
    // sync get pushed up so previously logged drinks aren't lost on first load.
    final pending =
        cached.where((e) => e.id == null && !e.isDeleted).toList();
    if (pending.isNotEmpty) {
      final stored = await _remote.insertAll(pending);
      if (stored != null) remote.addAll(stored);
    }

    // Server rows minus anything we've tombstoned locally; then re-attach the
    // tombstones so the cache keeps retrying until the server confirms.
    final live = remote.where((e) => !tombstoneIds.contains(e.id)).toList();
    final tombstones = cached.where((e) => e.isDeleted).toList();
    _entries = [...live, ...tombstones];
    await _persist();
  }

  Future<List<WaterEntry>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Re-read from disk so writes made by the notification background isolate
    // (quick-log) are visible here — SharedPreferences otherwise serves this
    // isolate's stale in-memory copy, and the next _persist would clobber them.
    await prefs.reload();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, raw);
  }

  /// Records a drink at the current time, inserting it in Supabase (so we get
  /// the row id) and caching locally. If the insert fails the entry is still
  /// kept locally (id null) and will be migrated up on a later [load].
  Future<WaterEntry> addEntry(int amountMl, {String type = 'Water'}) async {
    final local = WaterEntry(
      amountMl: amountMl,
      timestamp: DateTime.now(),
      type: type,
    );
    final stored = await _remote.insert(local);
    final entry = stored ?? local;
    _entries.add(entry);
    await _persist();
    return entry;
  }

  /// Soft-deletes an entry: marks it locally (a tombstone kept in the cache) and
  /// stamps the cloud row. If the cloud call fails (offline) the tombstone
  /// remains and [load] retries the sync, so the delete is never lost.
  Future<void> deleteEntry(WaterEntry entry) async {
    final index = _entries.indexOf(entry);
    if (index == -1) return;
    final tomb = entry.copyWith(deletedAt: DateTime.now());
    _entries[index] = tomb;
    if (tomb.id != null) await _remote.delete(tomb.id!);
    await _persist();
  }

  /// Edits an existing entry's amount, type and/or time. Updates the cache and
  /// (best-effort) the cloud row; a failed cloud update still keeps the local
  /// edit, which a later sync can reconcile.
  Future<void> updateEntry(
    WaterEntry entry, {
    int? amountMl,
    String? type,
    DateTime? timestamp,
  }) async {
    final index = _entries.indexOf(entry);
    if (index == -1) return;
    final edited = entry.copyWith(
      amountMl: amountMl,
      type: type,
      timestamp: timestamp,
    );
    _entries[index] = edited;
    if (edited.id != null) await _remote.update(edited);
    await _persist();
  }

  /// Drops all in-memory and cached entries. Called on sign-out so the next
  /// user on a shared device doesn't see the previous account's data.
  Future<void> clear() async {
    _entries = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
  }

  /// Removes the most recently logged entry (used by Undo).
  Future<void> removeLast() async {
    final last = lastEntry;
    if (last != null) await deleteEntry(last);
  }

  /// Entries newest-first, for the history list.
  List<WaterEntry> get entriesNewestFirst {
    final list = [..._live];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Effective (hydration-weighted) millilitres logged on the given day.
  int totalForDay(DateTime day) {
    return _live
        .where((e) => _isSameDay(e.timestamp, day))
        .fold(0, (sum, e) => sum + e.effectiveMl);
  }

  int get todayTotal => totalForDay(DateTime.now());

  /// Raw (unweighted) millilitres logged today, grouped by drink-type name.
  /// Drives the "Today's Mix" bars and the coffee-vs-water buddy nudge — both
  /// compare what was actually poured, so they use raw volume, not the
  /// hydration-weighted total.
  Map<String, int> todayByType([DrinkCatalog catalog = const DrinkCatalog()]) {
    final today = DateTime.now();
    final byType = <String, int>{};
    for (final e in _live.where((e) => _isSameDay(e.timestamp, today))) {
      // Resolve through the catalog (built-ins + the user's custom drinks) so a
      // logged custom drink keeps its own name and gets its own mix bar, while
      // legacy/unknown type names still fold into a real drink type instead of
      // becoming an invisible bucket that inflates the total.
      final name = catalog.byName(e.type).name;
      byType[name] = (byType[name] ?? 0) + e.amountMl;
    }
    return byType;
  }

  /// Entries logged on [day], earliest first.
  List<WaterEntry> entriesForDay(DateTime day) {
    return _live.where((e) => _isSameDay(e.timestamp, day)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Today's entries in the order they were logged (earliest first). Drives the
  /// Stats "Today" timeline, which shows *when* through the day you drank.
  List<WaterEntry> todayEntries() => entriesForDay(DateTime.now());

  /// Hydration-weighted totals for each day of [month]/[year], keyed by
  /// day-of-month (1-based); days with no entries are absent. Drives the History
  /// calendar heatmap.
  Map<int, int> monthTotals(int year, int month) {
    final totals = <int, int>{};
    for (final e in _live) {
      if (e.timestamp.year == year && e.timestamp.month == month) {
        totals[e.timestamp.day] =
            (totals[e.timestamp.day] ?? 0) + e.effectiveMl;
      }
    }
    return totals;
  }

  /// The date of the earliest logged entry, or null when nothing's logged.
  /// Bounds how far back the History calendar can page.
  DateTime? get firstEntryDate {
    final live = _live;
    if (live.isEmpty) return null;
    return live
        .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b)
        .timestamp;
  }

  /// Today's hydration-weighted intake bucketed into 24 hours (index 0 = 12am,
  /// 23 = 11pm). Always 24 entries so the hourly chart has a fixed axis; empty
  /// hours are 0. Uses [WaterEntry.effectiveMl] to stay consistent with the
  /// day/week chart (a coffee counts for what it really hydrates).
  List<HourTotal> todayByHour() {
    final today = DateTime.now();
    final buckets = List<int>.filled(24, 0);
    for (final e in _live.where((e) => _isSameDay(e.timestamp, today))) {
      buckets[e.timestamp.hour] += e.effectiveMl;
    }
    return [
      for (var h = 0; h < 24; h++) HourTotal(hour: h, totalMl: buckets[h]),
    ];
  }

  /// The most recent entry, or null if nothing has been logged yet.
  WaterEntry? get lastEntry {
    final live = _live;
    if (live.isEmpty) return null;
    return live.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
  }

  /// Totals for the last 7 days, oldest first. Index 6 is today.
  List<DayTotal> last7Days() => lastNDays(7);

  /// Totals for the last [n] days, oldest first. The last entry is today.
  List<DayTotal> lastNDays(int n) {
    final today = DateTime.now();
    return List.generate(n, (i) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: n - 1 - i));
      return DayTotal(day: day, totalMl: totalForDay(day));
    });
  }

  /// Live streak state for [goalMl]. Keeps yesterday's run visible through today
  /// until the day ends, so it doesn't read as "0 days" before the first drink.
  StreakStatus streakStatus(int goalMl) => computeStreak(
        goalMl: goalMl,
        today: DateTime.now(),
        totalForDay: totalForDay,
      );

  /// Number of consecutive goal-met days ending today (today counts once met).
  int currentStreak(int goalMl) => streakStatus(goalMl).count;

  /// A whole-history snapshot used to evaluate achievements.
  HydrationStats statsFor(int goalMl) {
    final live = _live;
    if (live.isEmpty) return HydrationStats.empty;

    final lifetime = live.fold(0, (sum, e) => sum + e.effectiveMl);

    // Collapse entries into per-day effective totals.
    final perDay = <DateTime, int>{};
    for (final e in live) {
      final day = DateTime(
        e.timestamp.year,
        e.timestamp.month,
        e.timestamp.day,
      );
      perDay[day] = (perDay[day] ?? 0) + e.effectiveMl;
    }

    // Days that met the goal, oldest first.
    final metDays = perDay.entries
        .where((e) => e.value >= goalMl)
        .map((e) => e.key)
        .toList()
      ..sort();

    // Longest run of consecutive met days.
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final day in metDays) {
      if (prev != null && day.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = day;
    }

    return HydrationStats(
      entryCount: live.length,
      lifetimeMl: lifetime,
      bestStreak: best,
      daysGoalMet: metDays.length,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A single day's total, used by the weekly chart.
class DayTotal {
  const DayTotal({required this.day, required this.totalMl});

  final DateTime day;
  final int totalMl;
}

/// One hour's total (0 = 12am … 23 = 11pm), used by the Today hourly chart.
class HourTotal {
  const HourTotal({required this.hour, required this.totalMl});

  final int hour;
  final int totalMl;
}
