import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_entry.dart';
import '../models/achievement.dart';

/// Persists logged water entries on the device (no backend) and exposes the
/// aggregates the UI needs: today's total, the last 7 days, and the streak.
class HydrationRepository {
  static const _entriesKey = 'water_entries_v1';

  List<WaterEntry> _entries = [];

  List<WaterEntry> get entries => List.unmodifiable(_entries);

  /// Loads saved entries from disk. Call once on startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) {
      _entries = [];
      return;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _entries = decoded
        .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, raw);
  }

  /// Records a drink at the current time and saves.
  Future<WaterEntry> addEntry(int amountMl, {String type = 'Still Water'}) async {
    final entry = WaterEntry(
      amountMl: amountMl,
      timestamp: DateTime.now(),
      type: type,
    );
    _entries.add(entry);
    await _persist();
    return entry;
  }

  /// Total millilitres logged on the given day (defaults to today).
  int totalForDay(DateTime day) {
    return _entries
        .where((e) => _isSameDay(e.timestamp, day))
        .fold(0, (sum, e) => sum + e.amountMl);
  }

  int get todayTotal => totalForDay(DateTime.now());

  /// The most recent entry, or null if nothing has been logged yet.
  WaterEntry? get lastEntry {
    if (_entries.isEmpty) return null;
    return _entries.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
  }

  /// Totals for the last 7 days, oldest first. Index 6 is today.
  List<DayTotal> last7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      return DayTotal(day: day, totalMl: totalForDay(day));
    });
  }

  /// Number of consecutive days (ending today) that met [goalMl].
  int currentStreak(int goalMl) {
    var streak = 0;
    final today = DateTime.now();
    for (var i = 0; ; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (totalForDay(day) >= goalMl) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// A whole-history snapshot used to evaluate achievements.
  HydrationStats statsFor(int goalMl) {
    if (_entries.isEmpty) return HydrationStats.empty;

    final lifetime = _entries.fold(0, (sum, e) => sum + e.amountMl);

    // Collapse entries into per-day totals.
    final perDay = <DateTime, int>{};
    for (final e in _entries) {
      final day = DateTime(
        e.timestamp.year,
        e.timestamp.month,
        e.timestamp.day,
      );
      perDay[day] = (perDay[day] ?? 0) + e.amountMl;
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
      entryCount: _entries.length,
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
