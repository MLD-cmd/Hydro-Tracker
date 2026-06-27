import 'package:flutter/material.dart';
import 'drink_type.dart';

/// A saved quick-log button — a labelled amount, e.g. "Nalgene / 600ml".
/// Tapping it logs [amountMl] of the currently-selected drink in a single tap.
/// Built-ins are client-side constants (no [id]); custom presets round-trip
/// through Supabase. Mirrors the [DrinkType] built-in/custom split.
class BottlePreset {
  const BottlePreset({
    required this.label,
    required this.amountMl,
    required this.iconKey,
    this.id,
  });

  /// Builds a user-defined preset from persisted primitives.
  factory BottlePreset.custom({
    required String id,
    required String label,
    required int amountMl,
    required String iconKey,
  }) =>
      BottlePreset(id: id, label: label, amountMl: amountMl, iconKey: iconKey);

  /// Null for the built-in set; the Supabase row id for custom presets.
  final String? id;
  final String label;
  final int amountMl;

  /// Stored icon key, resolved through the shared drink icon map.
  final String iconKey;

  bool get isCustom => id != null;

  /// The resolved icon (reuses the drink icon set so presets stay consistent).
  IconData get icon => iconForKey(iconKey);
}

/// The built-in presets every user starts with — a glass, a bottle, a large
/// bottle. Mirrors [kDrinkTypes]: client-side constants, no id, stable order.
const List<BottlePreset> kBottlePresets = [
  BottlePreset(label: 'Glass', amountMl: 250, iconKey: 'local_drink'),
  BottlePreset(label: 'Bottle', amountMl: 500, iconKey: 'water_drop'),
  BottlePreset(label: 'Large', amountMl: 750, iconKey: 'sports'),
];
