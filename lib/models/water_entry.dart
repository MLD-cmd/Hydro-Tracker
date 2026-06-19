import 'drink_type.dart';

/// A single logged drink. Stored locally and used to compute daily totals,
/// the weekly chart, and streaks.
class WaterEntry {
  const WaterEntry({
    required this.amountMl,
    required this.timestamp,
    this.type = 'Water',
  });

  final int amountMl;
  final DateTime timestamp;
  final String type;

  /// Hydrating millilitres after applying the drink type's weight.
  int get effectiveMl => drinkTypeByName(type).effective(amountMl);

  Map<String, dynamic> toJson() => {
    'amountMl': amountMl,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
  };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    amountMl: json['amountMl'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: (json['type'] as String?) ?? 'Still Water',
  );
}
