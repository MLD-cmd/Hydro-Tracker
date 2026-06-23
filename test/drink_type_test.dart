import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/drink_type.dart';

void main() {
  test('icon key maps to an IconData and back', () {
    expect(drinkIconKeys.contains('water_drop'), isTrue);
    expect(iconForKey('water_drop'), isNotNull);
    expect(iconForKey('unknown_key'), iconForKey(drinkIconKeys.first));
  });

  test('a custom drink parses its hex colour', () {
    final t = DrinkType.custom(
      id: 'c1',
      name: 'Soda',
      hydration: 0.5,
      iconKey: 'local_drink',
      colorHex: 'FF5733',
    );
    expect(t.color.toARGB32() & 0x00FFFFFF, 0xFF5733);
    expect(t.name, 'Soda');
    expect(t.id, 'c1');
    expect(t.isCustom, isTrue);
  });

  test('effective millilitres apply hydration weight', () {
    final t = DrinkType.custom(
      id: 'c1',
      name: 'Soda',
      hydration: 0.5,
      iconKey: 'local_drink',
      colorHex: 'FF5733',
    );
    expect(t.effective(200), 100);
  });
}
