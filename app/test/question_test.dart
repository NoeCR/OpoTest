import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/models/question.dart';

void main() {
  group('Question.fromApiMap', () {
    test('parsea campos del JSON de temario', () {
      final q = Question.fromApiMap({
        'order': '3',
        'q': {
          'text_es': '¿Cuál es correcta?',
          'answer1_es': 'Opción 1',
          'answer2_es': 'Opción 2',
          'answer3_es': 'Opción 3',
          'answer4_es': 'Opción 4',
          'solution': '2',
          'textClarification_es': '<p>Nota</p>',
        },
      });

      expect(q.order, 3);
      expect(q.text, '¿Cuál es correcta?');
      expect(q.answers, ['Opción 1', 'Opción 2', 'Opción 3', 'Opción 4']);
      expect(q.solution, 2);
      expect(q.clarificationHtml, '<p>Nota</p>');
    });

    test('valores ausentes usan defaults seguros', () {
      final q = Question.fromApiMap(const {});

      expect(q.order, 0);
      expect(q.text, isEmpty);
      expect(q.answers, everyElement(isEmpty));
      expect(q.solution, 0);
    });
  });

  group('TestDefinition.fromApiJson', () {
    test('lee preguntas desde q como mapa anidado', () {
      final def = TestDefinition.fromApiJson({
        'test': {
          'id': '501',
          'name': 'Test Constitución',
          'type': 'test',
          'q': {
            '1': [
              {
                'order': '1',
                'q': {
                  'text_es': 'P1',
                  'answer1_es': 'A',
                  'answer2_es': 'B',
                  'answer3_es': 'C',
                  'answer4_es': 'D',
                  'solution': '1',
                },
              },
            ],
          },
        },
      });

      expect(def.id, '501');
      expect(def.name, 'Test Constitución');
      expect(def.type, 'test');
      expect(def.questions, hasLength(1));
      expect(def.questions.first.text, 'P1');
    });

    test('lee preguntas desde q como lista [meta, items]', () {
      final def = TestDefinition.fromApiJson({
        'test': {
          'id': '502',
          'name': 'Examen',
          'type': 'exam',
          'q': [
            {'meta': true},
            [
              {
                'order': '1',
                'q': {
                  'text_es': 'P examen',
                  'answer1_es': 'A',
                  'answer2_es': 'B',
                  'answer3_es': 'C',
                  'answer4_es': 'D',
                  'solution': '3',
                },
              },
            ],
          ],
        },
      });

      expect(def.id, '502');
      expect(def.type, 'exam');
      expect(def.questions.single.solution, 3);
    });

    test('toApiJson roundtrip conserva id, nombre y preguntas', () {
      final original = TestDefinition.fromApiJson({
        'test': {
          'id': 'mixed_random_99',
          'name': 'Mixto · 1 preguntas',
          'type': 'test',
          'q': {
            '1': [
              {
                'order': '1',
                'q': {
                  'text_es': 'Enunciado',
                  'answer1_es': 'A',
                  'answer2_es': 'B',
                  'answer3_es': 'C',
                  'answer4_es': 'D',
                  'solution': '4',
                  'textClarification_es': '<p>Nota</p>',
                },
              },
            ],
          },
        },
      });

      final restored = TestDefinition.fromApiJson(original.toApiJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.questions.single.text, 'Enunciado');
      expect(restored.questions.single.solution, 4);
      expect(restored.questions.single.clarificationHtml, '<p>Nota</p>');
    });

    test('toApiJson roundtrip conserva el origen de preguntas clonadas', () {
      const original = TestDefinition(
        id: 'reinforcement_random_1',
        name: 'Refuerzo',
        type: 'reinforcement',
        questions: [
          Question(
            order: 1,
            text: 'P1',
            answers: ['A', 'B', 'C', 'D'],
            solution: 1,
            clarificationHtml: '',
            sourceTestId: '1001',
            sourceQuestionIndex: 2,
          ),
        ],
      );

      final restored = TestDefinition.fromApiJson(original.toApiJson());
      expect(restored.questions.single.sourceTestId, '1001');
      expect(restored.questions.single.sourceQuestionIndex, 2);
    });
  });

  group('originAnswersFrom', () {
    test('solo incluye preguntas clonadas con respuesta', () {
      const questions = [
        Question(
          order: 1,
          text: 'Con origen',
          answers: ['A', 'B', 'C', 'D'],
          solution: 2,
          clarificationHtml: '',
          sourceTestId: '1001',
          sourceQuestionIndex: 3,
        ),
        Question(
          order: 2,
          text: 'Sin origen',
          answers: ['A', 'B', 'C', 'D'],
          solution: 1,
          clarificationHtml: '',
        ),
      ];

      final outcomes = originAnswersFrom(
        questions: questions,
        answers: const {0: 2, 1: 1},
      );
      expect(outcomes, hasLength(1));
      expect(outcomes.single.testId, '1001');
      expect(outcomes.single.questionIndex, 3);
      expect(outcomes.single.correct, isTrue);
    });
  });
}
