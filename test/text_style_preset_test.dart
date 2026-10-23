import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klip/features/editor/domain/text_style_preset.dart';

void main() {
  test('text presets have unique IDs and visible styles', () {
    final ids = TextStylePreset.all.map((preset) => preset.id).toSet();
    expect(ids.length, TextStylePreset.all.length);
    expect(TextStylePreset.all.length, greaterThanOrEqualTo(8));
    expect(TextStylePreset.byId('neon').strokeColor, isNotNull);
    expect(TextStylePreset.byId('label').background, isNotNull);
    expect(TextStylePreset.byId('classic').color, isNot(Colors.transparent));
  });

  test('unknown preset falls back to classic', () {
    expect(TextStylePreset.byId('missing').id, 'classic');
  });
}
