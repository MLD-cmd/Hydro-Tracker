import 'dart:convert';
import '../models/water_entry.dart';

/// SharedPreferences key holding the cached water-entry list — a JSON array of
/// [WaterEntry.toJson]. Shared by [HydrationRepository] and the notification
/// background isolate so both read and write the exact same store.
const String kEntriesCacheKey = 'water_entries_v1';

/// Appends [entry] to the cached entry list encoded in [rawJson] (null or empty
/// starts a fresh list) and returns the new JSON string.
///
/// Pure — no I/O — so the append logic is unit-testable and byte-identical in
/// the app and in the notification background isolate, which is the one real
/// correctness risk for quick-log: cache-format drift between the two writers.
String appendCachedEntry(String? rawJson, WaterEntry entry) {
  final list = <dynamic>[];
  if (rawJson != null && rawJson.isNotEmpty) {
    list.addAll(jsonDecode(rawJson) as List<dynamic>);
  }
  list.add(entry.toJson());
  return jsonEncode(list);
}
