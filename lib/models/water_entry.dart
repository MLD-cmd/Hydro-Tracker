import 'drink_type.dart';

/// A single logged drink. Used to compute daily totals, the weekly chart, and
/// streaks. Each entry is backed by a row in Supabase `water_entries`; [id] is
/// that row's uuid. It's null only for an entry created locally that hasn't been
/// pushed to the cloud yet (offline, or pending the one-time migration).
class WaterEntry {
  const WaterEntry({
    required this.amountMl,
    required this.timestamp,
    this.type = 'Water',
    this.id,
    this.deletedAt,
  });

  final String? id;
  final int amountMl;
  final DateTime timestamp;
  final String type;

  /// When set, this entry has been deleted (soft-delete). Kept locally as a
  /// tombstone so an offline delete survives the next sync instead of the row
  /// reappearing. Excluded from all totals and lists.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Hydrating millilitres after applying the drink type's weight.
  int get effectiveMl => drinkTypeByName(type).effective(amountMl);

  WaterEntry copyWith({
    String? id,
    int? amountMl,
    DateTime? timestamp,
    String? type,
    DateTime? deletedAt,
  }) => WaterEntry(
    id: id ?? this.id,
    amountMl: amountMl ?? this.amountMl,
    timestamp: timestamp ?? this.timestamp,
    type: type ?? this.type,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'amountMl': amountMl,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    id: json['id'] as String?,
    amountMl: json['amountMl'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: (json['type'] as String?) ?? 'Still Water',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
  );

  /// Builds an entry from a Supabase `water_entries` row.
  factory WaterEntry.fromRow(Map<String, dynamic> r) => WaterEntry(
    id: r['id'] as String?,
    amountMl: (r['amount_ml'] as num).toInt(),
    timestamp: DateTime.parse(r['logged_at'] as String).toLocal(),
    type: (r['type'] as String?) ?? 'Water',
    deletedAt: r['deleted_at'] == null
        ? null
        : DateTime.parse(r['deleted_at'] as String).toLocal(),
  );

  /// Serialises to a Supabase `water_entries` row for the given user. Omits
  /// `id` so Postgres assigns the uuid (and `created_at` defaults server-side).
  Map<String, dynamic> toRow(String userId) => {
    if (id != null) 'id': id,
    'user_id': userId,
    'amount_ml': amountMl,
    'type': type,
    'logged_at': timestamp.toUtc().toIso8601String(),
  };
}
