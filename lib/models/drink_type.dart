import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A kind of drink and how much it counts toward hydration. Coffee and tea
/// hydrate a little less than water; coconut water a touch more.
class DrinkType {
  const DrinkType({
    required this.name,
    required this.icon,
    required this.color,
    required this.hydration,
    this.id,
    this.iconKey,
  });

  /// Builds a user-defined drink from persisted primitives (icon key + hex).
  factory DrinkType.custom({
    required String id,
    required String name,
    required double hydration,
    required String iconKey,
    required String colorHex,
  }) {
    return DrinkType(
      id: id,
      name: name,
      hydration: hydration,
      iconKey: iconKey,
      icon: iconForKey(iconKey),
      color: _colorFromHex(colorHex),
    );
  }

  /// Null for the built-in catalogue; the Supabase row id for custom drinks.
  final String? id;
  final String name;
  final IconData icon;
  final Color color;
  final double hydration; // multiplier applied to the raw millilitres

  /// The stored icon key for custom drinks (null for built-ins).
  final String? iconKey;

  bool get isCustom => id != null;

  /// Effective hydrating millilitres for a raw [amountMl] of this drink.
  int effective(int amountMl) => (amountMl * hydration).round();
}

/// Parses a 6-hex-digit RRGGBB string into an opaque Color.
Color _colorFromHex(String hex) {
  final value = int.tryParse(hex, radix: 16) ?? 0x4FC3F7;
  return Color(0xFF000000 | value);
}

/// The fixed set of icons a custom drink may use (key -> IconData). Storing a
/// key (not an IconData) is what lets custom drinks round-trip through Supabase.
const Map<String, IconData> _iconByKey = {
  'water_drop': Icons.water_drop_rounded,
  'local_drink': Icons.local_drink_rounded,
  'local_bar': Icons.local_bar_rounded,
  'coffee': Icons.local_cafe_rounded,
  'tea': Icons.emoji_food_beverage_rounded,
  'sports': Icons.sports_bar_rounded,
  'bubble': Icons.bubble_chart_rounded,
};

List<String> get drinkIconKeys => _iconByKey.keys.toList();

/// Resolves an icon key, defaulting to the first icon for unknown keys.
IconData iconForKey(String key) => _iconByKey[key] ?? _iconByKey.values.first;

const List<DrinkType> kDrinkTypes = [
  DrinkType(
    name: 'Water',
    icon: Icons.water_drop_rounded,
    color: AppColors.turquoise,
    hydration: 1.0,
  ),
  DrinkType(
    name: 'Coconut',
    icon: Icons.local_drink_rounded,
    color: AppColors.secondaryAccent,
    hydration: 1.1,
  ),
  DrinkType(
    name: 'Juice',
    icon: Icons.local_bar_rounded,
    color: Color(0xFFFFA62B),
    hydration: 0.85,
  ),
  DrinkType(
    name: 'Tea',
    icon: Icons.emoji_food_beverage_rounded,
    color: Color(0xFF7BB662),
    hydration: 0.9,
  ),
  DrinkType(
    name: 'Coffee',
    icon: Icons.local_cafe_rounded,
    color: Color(0xFF9C6B4A),
    hydration: 0.6,
  ),
];

/// Looks up a drink type by name, defaulting to Water for unknown/legacy data.
DrinkType drinkTypeByName(String name) {
  for (final t in kDrinkTypes) {
    if (t.name == name) return t;
  }
  return kDrinkTypes.first;
}

/// Drinks that hydrate this much or more (tea, coconut, water) are never worth
/// nagging about — they keep you roughly as hydrated as plain water. Anything
/// below the line (coffee, juice) is "worth a gentle word" when it out-pours
/// water. Tying the trigger to the hydration weight keeps Splash a supportive
/// coach rather than the food police, and scales to any drink added later.
const double kGentleNudgeBelow = 0.9;

/// A gentle "drink some water" prompt from Splash, named after whichever
/// less-hydrating drink is leading the day.
class HydrationNudge {
  const HydrationNudge({
    required this.leader,
    required this.title,
    required this.line,
  });

  final DrinkType leader;
  final String title;
  final String line;
}

/// Decides whether Splash should nudge toward water, given today's raw
/// millilitres per drink type. Returns null when water is keeping up.
///
/// Rule: sum the *less-hydrating* drinks (coffee, juice). If together they
/// out-pour water, nudge — and name whichever of them leads. Tea and coconut
/// never count toward this, so they never set it off.
HydrationNudge? hydrationNudgeFor(Map<String, int> byType) {
  final water = byType['Water'] ?? 0;

  // Less-hydrating drinks that were actually logged today, most-poured first.
  final lessHydrating = kDrinkTypes
      .where((t) => t.hydration < kGentleNudgeBelow)
      .map((t) => (type: t, ml: byType[t.name] ?? 0))
      .where((e) => e.ml > 0)
      .toList()
    ..sort((a, b) => b.ml.compareTo(a.ml));

  if (lessHydrating.isEmpty) return null;

  final lessHydratingTotal = lessHydrating.fold(0, (sum, e) => sum + e.ml);
  if (lessHydratingTotal <= water) return null; // water is keeping up — all good

  return _nudgeCopyFor(lessHydrating.first.type);
}

HydrationNudge _nudgeCopyFor(DrinkType leader) {
  switch (leader.name) {
    case 'Coffee':
      return HydrationNudge(
        leader: leader,
        title: 'More coffee than water ☕',
        line: "Let's balance it out — grab a glass of water for me? 💧",
      );
    case 'Juice':
      return HydrationNudge(
        leader: leader,
        title: 'Lots of juice today 🍹',
        line: 'Tasty — but your body would love some plain water too. 💧',
      );
    default:
      // Any future low-hydration drink (soda, energy drinks…) lands here.
      return HydrationNudge(
        leader: leader,
        title: 'Time to top up on water',
        line: "Let's even things out with a glass of water. 💧",
      );
  }
}
