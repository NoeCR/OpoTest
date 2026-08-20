import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/widgets/score_stars.dart';
import 'package:testea_local/widgets/test_picker_card.dart';

void main() {
  group('starsFromPercent', () {
    test('null devuelve cero estrellas', () {
      expect(starsFromPercent(null), 0);
    });

    test('100% son 5 estrellas', () {
      expect(starsFromPercent(100), 5);
    });

    test('50% son 2.5 estrellas', () {
      expect(starsFromPercent(50), 2.5);
    });

    test('valores negativos o >100 se clampan', () {
      expect(starsFromPercent(-10), 0);
      expect(starsFromPercent(150), 5);
    });
  });

  group('scoreAccentColor', () {
    test('umbrales de color por porcentaje', () {
      expect(scoreAccentColor(null), const Color(0xFF6B7280));
      expect(scoreAccentColor(100), const Color(0xFF15803D));
      expect(scoreAccentColor(80), const Color(0xFF2EAD5B));
      expect(scoreAccentColor(50), const Color(0xFFB45309));
      expect(scoreAccentColor(10), const Color(0xFFC62828));
    });
  });
}
