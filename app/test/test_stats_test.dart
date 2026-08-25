import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/models/test_stats.dart';

void main() {
  group('TestStats', () {
    test('sin intentos no tiene datos', () {
      const stats = TestStats();

      expect(stats.hasAttempts, isFalse);
      expect(stats.lastPerfect, isFalse);
      expect(stats.avgLabel, '--');
      expect(stats.bestLabel, '--');
      expect(stats.lastLabel, '--');
      expect(stats.displayPercent, isNull);
    });

    test('lastPerfect detecta 100%', () {
      const stats = TestStats(lastPercent: 100, attempts: 1);

      expect(stats.lastPerfect, isTrue);
      expect(stats.lastLabel, '100%');
      expect(stats.displayPercent, 100);
    });

    test('displayPercent prioriza último intento', () {
      const stats = TestStats(
        avgPercent: 60,
        bestPercent: 80,
        lastPercent: 45,
        attempts: 3,
      );

      expect(stats.displayPercent, 45);
      expect(stats.avgLabel, '60%');
      expect(stats.bestLabel, '80%');
    });

    test('displayPercent usa mejor si no hay último', () {
      const stats = TestStats(bestPercent: 72, attempts: 2);

      expect(stats.displayPercent, 72);
    });
  });
}
