import '../models/bottle_preset.dart';

/// The full set of quick-log presets: the built-in constants plus the user's
/// custom ones. Mirrors [DrinkCatalog] so presets show up as one-tap buttons
/// alongside the drink-type selector.
class PresetCatalog {
  const PresetCatalog({this.custom = const []});

  final List<BottlePreset> custom;

  /// Built-ins first (stable order), then the user's custom presets.
  List<BottlePreset> get all => [...kBottlePresets, ...custom];
}
