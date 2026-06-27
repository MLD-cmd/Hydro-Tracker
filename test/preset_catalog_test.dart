import 'package:flutter_test/flutter_test.dart';
import 'package:hydro_tracker/models/bottle_preset.dart';
import 'package:hydro_tracker/domain/preset_catalog.dart';

void main() {
  test('catalog combines built-ins and custom presets', () {
    final custom = BottlePreset.custom(
      id: 'p1',
      label: 'Nalgene',
      amountMl: 600,
      iconKey: 'water_drop',
    );
    final catalog = PresetCatalog(custom: [custom]);
    expect(catalog.all.length, kBottlePresets.length + 1);
    expect(catalog.all.last.label, 'Nalgene');
  });

  test('built-ins come first in stable order', () {
    const catalog = PresetCatalog();
    expect(catalog.all.length, kBottlePresets.length);
    expect(catalog.all.first.label, kBottlePresets.first.label);
  });
}
