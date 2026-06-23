import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/drink_type.dart';
import 'package:hydro_tracker/services/drink_catalog.dart';

void main() {
  test('catalog combines built-ins and custom drinks', () {
    final custom = DrinkType.custom(
      id: 'c1',
      name: 'Soda',
      hydration: 0.5,
      iconKey: 'local_drink',
      colorHex: 'FF5733',
    );
    final catalog = DrinkCatalog(custom: [custom]);
    expect(catalog.all.length, kDrinkTypes.length + 1);
    expect(catalog.all.last.name, 'Soda');
  });

  test('byName resolves built-ins, custom, then defaults to first', () {
    final custom = DrinkType.custom(
      id: 'c1',
      name: 'Soda',
      hydration: 0.5,
      iconKey: 'local_drink',
      colorHex: 'FF5733',
    );
    final catalog = DrinkCatalog(custom: [custom]);
    expect(catalog.byName('Water').name, 'Water');
    expect(catalog.byName('Soda').name, 'Soda');
    expect(catalog.byName('Nonexistent').name, kDrinkTypes.first.name);
  });
}
