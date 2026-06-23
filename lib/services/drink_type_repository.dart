import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink_type.dart';

/// Reads/writes the signed-in user's custom drink types. Mirrors the other
/// repositories: returns null / swallows errors when signed out or offline.
class DrinkTypeRepository {
  DrinkTypeRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  /// The user's custom drinks, or null when signed out / on failure.
  Future<List<DrinkType>?> fetchAll() async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final rows = await _db
          .from('drink_types')
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

  /// Inserts a custom drink and returns it with its server id, or null.
  Future<DrinkType?> insert({
    required String name,
    required double hydration,
    required String iconKey,
    required String colorHex,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final row = await _db
          .from('drink_types')
          .insert({
            'user_id': userId,
            'name': name,
            'hydration': hydration,
            'icon_key': iconKey,
            'color_hex': colorHex,
          })
          .select()
          .single();
      return _fromRow(row);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a custom drink by id. Best-effort.
  Future<void> delete(String id) async {
    if (_userId == null) return;
    try {
      await _db.from('drink_types').delete().eq('id', id);
    } catch (_) {
      // best-effort
    }
  }

  DrinkType _fromRow(Map<String, dynamic> r) => DrinkType.custom(
        id: r['id'] as String,
        name: r['name'] as String,
        hydration: (r['hydration'] as num).toDouble(),
        iconKey: r['icon_key'] as String,
        colorHex: r['color_hex'] as String,
      );
}
