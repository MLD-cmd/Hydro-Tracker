import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bottle_preset.dart';

/// Reads/writes the signed-in user's custom quick-log presets. Mirrors
/// [DrinkTypeRepository]: returns null / swallows errors when signed out or
/// offline.
class PresetRepository {
  PresetRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  /// The user's custom presets, or null when signed out / on failure.
  Future<List<BottlePreset>?> fetchAll() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final rows = await _db
          .from('bottle_presets')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return (rows as List)
          .map((r) => _fromRow(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Inserts a custom preset and returns it with its server id, or null.
  Future<BottlePreset?> insert({
    required String label,
    required int amountMl,
    required String iconKey,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final row = await _db
          .from('bottle_presets')
          .insert({
            'user_id': userId,
            'label': label,
            'amount_ml': amountMl,
            'icon_key': iconKey,
          })
          .select()
          .single();
      return _fromRow(row);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a custom preset by id. Best-effort.
  Future<void> delete(String id) async {
    if (_userId == null) return;
    try {
      await _db.from('bottle_presets').delete().eq('id', id);
    } catch (_) {
      // best-effort
    }
  }

  BottlePreset _fromRow(Map<String, dynamic> r) => BottlePreset.custom(
        id: r['id'] as String,
        label: r['label'] as String,
        amountMl: (r['amount_ml'] as num).toInt(),
        iconKey: (r['icon_key'] as String?) ?? 'local_drink',
      );
}
