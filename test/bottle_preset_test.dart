import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/bottle_preset.dart';

void main() {
  test('a custom preset is flagged custom and resolves its icon', () {
    final p = BottlePreset.custom(
      id: 'p1',
      label: 'Nalgene',
      amountMl: 600,
      iconKey: 'water_drop',
    );
    expect(p.isCustom, isTrue);
    expect(p.amountMl, 600);
    expect(p.label, 'Nalgene');
    expect(p.icon, isNotNull);
  });

  test('built-in presets have no id and are not custom', () {
    expect(kBottlePresets, isNotEmpty);
    expect(kBottlePresets.every((p) => p.id == null), isTrue);
    expect(kBottlePresets.first.isCustom, isFalse);
  });
}
