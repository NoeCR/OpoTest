import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/models/question.dart';
import 'package:testea_local/services/test_scoring.dart';

Question _q(int order, {int solution = 1}) => Question(
      order: order,
      text: 'P$order',
      answers: const ['A', 'B', 'C', 'D'],
      solution: solution,
      clarificationHtml: '',
    );

void main() {
  group('TestScoring', () {
    final questions = List.generate(4, (i) => _q(i + 1, solution: 1));

    test('sin penalización cuenta aciertos netos', () {
      final result = TestScoring.score(
        questions: questions,
        answers: {0: 1, 1: 1, 2: 2, 3: 0},
        errorFormat: 0,
      );

      expect(result.correct, 2);
      expect(result.incorrect, 1);
      expect(result.unanswered, 1);
      expect(result.netScore, 2.0);
      expect(result.percentScore, 50.0);
    });

    test('penalización 0.25 (formato 25)', () {
      final result = TestScoring.score(
        questions: questions,
        answers: {0: 1, 1: 2, 2: 2, 3: 2},
        errorFormat: 25,
      );

      expect(result.correct, 1);
      expect(result.incorrect, 3);
      expect(result.netScore, 0.3);
      expect(result.percentScore, 6.3);
    });

    test('penalización 0.33 (formato 33)', () {
      final result = TestScoring.score(
        questions: questions,
        answers: {0: 1, 1: 2, 2: 2, 3: 1},
        errorFormat: 33,
      );

      expect(result.correct, 2);
      expect(result.incorrect, 2);
      expect(result.netScore, closeTo(1.3, 0.01));
      expect(result.percentScore, closeTo(33.3, 0.1));
    });

    test('penalización 0.50 (formato 50)', () {
      final result = TestScoring.score(
        questions: questions,
        answers: {0: 1, 1: 2, 2: 1, 3: 2},
        errorFormat: 50,
      );

      expect(result.correct, 2);
      expect(result.incorrect, 2);
      expect(result.netScore, 1.0);
      expect(result.percentScore, 25.0);
    });

    test('penalización 1 (formato 100) no baja de cero', () {
      final result = TestScoring.score(
        questions: questions,
        answers: {0: 2, 1: 2, 2: 2, 3: 2},
        errorFormat: 100,
      );

      expect(result.correct, 0);
      expect(result.incorrect, 4);
      expect(result.netScore, 0.0);
      expect(result.percentScore, 0.0);
    });

    test('test perfecto alcanza 100%', () {
      final result = TestScoring.score(
        questions: questions,
        answers: {0: 1, 1: 1, 2: 1, 3: 1},
        errorFormat: 100,
      );

      expect(result.percentScore, 100.0);
      expect(result.unanswered, 0);
    });

    test('lista vacía devuelve cero', () {
      final result = TestScoring.score(
        questions: const [],
        answers: const {},
        errorFormat: 100,
      );

      expect(result.percentScore, 0.0);
      expect(result.unanswered, 0);
    });
  });
}
