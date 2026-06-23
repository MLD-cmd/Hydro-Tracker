import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/water_entry.dart';

/// Reads/writes the signed-in user's rows in the Supabase `water_entries`
/// table. Mirrors [ProfileRepository]'s style: returns null / swallows errors
/// when signed out or offline so the caller can fall back to its local cache.
///
/// RLS already restricts every row to its owner, so the only thing the client
/// must supply on insert is `user_id`.
class EntryRepository {
  EntryRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? Supabase.instance.client;

  String? get _userId => _db.auth.currentUser?.id;

  /// All of the current user's entries, oldest-first. Returns null when signed
  /// out or the fetch fails (offline / transient) so the caller uses its cache.
  Future<List<WaterEntry>?> fetchAll() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final rows = await _db
          .from('water_entries')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('logged_at');
      return (rows as List)
          .map((r) => WaterEntry.fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null; // offline / transient — caller falls back to local cache
    }
  }

  /// Inserts [entry] and returns it with the server-assigned id, or null on
  /// failure (signed out / offline) so the caller keeps the local-only copy.
  Future<WaterEntry?> insert(WaterEntry entry) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final row = await _db
          .from('water_entries')
          .insert(entry.toRow(userId))
          .select()
          .single();
      return WaterEntry.fromRow(row);
    } catch (_) {
      return null;
    }
  }

  /// Updates an existing row's amount, type and time. Best-effort; returns false
  /// when signed out / offline so the caller can keep a local-only edit.
  Future<bool> update(WaterEntry entry) async {
    final userId = _userId;
    if (userId == null || entry.id == null) return false;
    try {
      await _db
          .from('water_entries')
          .update({
            'amount_ml': entry.amountMl,
            'type': entry.type,
            'logged_at': entry.timestamp.toUtc().toIso8601String(),
          })
          .eq('id', entry.id!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Inserts many entries at once (used by the one-time migration of local
  /// logs). Returns the stored rows with their ids, or null on failure.
  Future<List<WaterEntry>?> insertAll(List<WaterEntry> entries) async {
    final userId = _userId;
    if (userId == null || entries.isEmpty) return null;
    try {
      final rows = await _db
          .from('water_entries')
          .insert(entries.map((e) => e.toRow(userId)).toList())
          .select();
      return (rows as List)
          .map((r) => WaterEntry.fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Soft-deletes the row with [id] by stamping `deleted_at`. Returns true on
  /// success, false when signed out / offline so the caller can keep a local
  /// tombstone to retry on the next sync.
  Future<bool> delete(String id) async {
    if (_userId == null) return false;
    try {
      await _db
          .from('water_entries')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
