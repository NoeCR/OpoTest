import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/random_tests/application/synthetic_test_builder.dart';
import 'package:opotest/models/question.dart';

void main() {
  group('SyntheticTestBuilder', () {
    test('construye test sintético con metadatos', () {
      final builder = SyntheticTestBuilder(timestampMs: 123);
      final pick = builder.build(
        idPrefix: 'mixed_random',
        namePrefix: 'Test mixto',
        type: 'mixed',
        questions: const [
          Question(
            order: 1,
            text: 'P1',
            answers: ['A', 'B', 'C', 'D'],
            solution: 1,
            clarificationHtml: '',
          ),
        ],
      );

      expect(pick.mixedTest?.id, 'mixed_random_123');
      expect(pick.mixedTest?.name, 'Test mixto · 1 preguntas');
      expect(pick.mixedTest?.type, 'mixed');
    });
  });
}
