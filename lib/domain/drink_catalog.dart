import '../models/drink_type.dart';

/// The full set of drink types in play: the built-in constants plus the user's
/// custom drinks. Replaces scattered direct reads of [kDrinkTypes] so custom
/// drinks show up everywhere (quick-log, mix card, history).
class DrinkCatalog {
  const DrinkCatalog({this.custom = const []});

  final List<DrinkType> custom;

  /// Built-ins first (stable order), then the user's custom drinks.
  List<DrinkType> get all => [...kDrinkTypes, ...custom];

  /// Resolves a drink by name across the whole catalog, defaulting to the first
  /// built-in for unknown/legacy names (matches the old [drinkTypeByName]).
  DrinkType byName(String name) {
    for (final t in all) {
      if (t.name == name) return t;
    }
    return kDrinkTypes.first;
  }
}
