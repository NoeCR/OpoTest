import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/weak_points/domain/weak_points.dart';

void main() {
  final now = DateTime(2026, 8, 28, 12);
  const laws = {
    '10': LawLabel(code: 'CE', name: 'Constitución'),
    '11': LawLabel(code: 'EBEP', name: 'Estatuto Básico'),
  };
  const titles = {
    '82': TitleLabel(lawId: '10', code: 'T1', name: 'Derechos'),
    '90': TitleLabel(lawId: '11', code: 'T4', name: 'Excedencia'),
  };

  TopicAttemptPoint point({
    required String testId,
    required String lawId,
    required double percent,
    Duration ago = Duration.zero,
    String? titleId,
  }) {
    return TopicAttemptPoint(
      testId: testId,
      lawId: lawId,
      titleId: titleId,
      percent: percent,
      finishedAt: now.subtract(ago),
    );
  }

  group('buildWeakTopics', () {
    test('agrega por ley y pone lo más flojo primero', () {
      final topics = buildWeakTopics(
        scope: WeakPointsScope.laws,
        laws: laws,
        titles: titles,
        attempts: [
          point(testId: '1001', lawId: '10', titleId: '82', percent: 80, ago: const Duration(hours: 2)),
          point(testId: '1002', lawId: '11', titleId: '90', percent: 40, ago: const Duration(hours: 1)),
          point(testId: '1001', lawId: '10', titleId: '82', percent: 90),
        ],
      );
      sortWeakTopics(topics, WeakPointsSort.weakest);

      expect(topics.map((t) => t.id), ['11', '10']);
      expect(topics.first.stats.lastPercent, 40);
      expect(topics.first.stats.attempts, 1);
      expect(topics.last.stats.lastPercent, 90);
      expect(topics.last.stats.avgPercent, 85);
      expect(topics.last.stats.attempts, 2);
    });

    test('ignora intentos sintéticos', () {
      final topics = buildWeakTopics(
        scope: WeakPointsScope.laws,
        laws: laws,
        titles: titles,
        attempts: [
          point(testId: 'mixed_random_1', lawId: '10', percent: 10),
          point(testId: '1001', lawId: '10', titleId: '82', percent: 70),
        ],
      );
      expect(topics, hasLength(1));
      expect(topics.single.stats.lastPercent, 70);
    });

    test('agrega por título', () {
      final topics = buildWeakTopics(
        scope: WeakPointsScope.titles,
        laws: laws,
        titles: titles,
        attempts: [
          point(testId: '1001', lawId: '10', titleId: '82', percent: 60),
          point(testId: '1002', lawId: '11', titleId: '90', percent: 30),
        ],
      );
      sortWeakTopics(topics, WeakPointsSort.weakest);
      expect(topics.first.id, '90');
      expect(topics.first.subtitle, contains('EBEP'));
    });
  });

  group('sortWeakTopics', () {
    test('por intentos deja arriba el que más se ha practicado', () {
      final topics = buildWeakTopics(
        scope: WeakPointsScope.laws,
        laws: laws,
        titles: titles,
        attempts: [
          point(testId: '1001', lawId: '10', percent: 50, ago: const Duration(hours: 2)),
          point(testId: '1001', lawId: '10', percent: 60, ago: const Duration(hours: 1)),
          point(testId: '1002', lawId: '11', percent: 20),
        ],
      );
      sortWeakTopics(topics, WeakPointsSort.attempts);
      expect(topics.first.id, '10');
      expect(topics.first.stats.attempts, 2);
    });
  });
}
