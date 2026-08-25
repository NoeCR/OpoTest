import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/failed_questions_export/application/failed_questions_collector.dart';
import 'package:opotest/features/failed_questions_export/application/failed_questions_html_report.dart';
import 'package:opotest/features/failed_questions_export/domain/failed_question_item.dart';
import 'package:opotest/features/failed_questions_export/domain/failed_questions_range.dart';
import 'package:opotest/models/local_user.dart';
import 'package:opotest/models/question.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('FailedQuestionsCollector', () {
    late AppDatabase db;
    late FailedQuestionsCollector collector;
    late LocalUser user;

    setUp(() async {
      db = await setUpTestDatabase();
      collector = FailedQuestionsCollector(db);
      user = LocalUser(
        id: 'user-1',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'CE', 'name_es': 'Constitución', 'order': '1'},
        ],
        'qByLawNew': {'10': {}},
      });
      await db.importTitle('10', {
        'title': {'id': '82', 'code': 'T1', 'name_es': 'Derechos fundamentales', 'order': '1'},
      });
      await db.upsertOfficialTest(
        sampleTestJson(id: '1001', lawId: '10', titleId: '82', questionCount: 4),
      );
    });

    tearDown(tearDownTestDatabase);

    FailedQuestionsRange rangeAround(DateTime at) {
      return FailedQuestionsRange(
        from: at.subtract(const Duration(days: 1)),
        to: at.add(const Duration(days: 1)),
        preset: FailedQuestionsPreset.custom,
      );
    }

    Future<void> saveAttempt({
      required String id,
      required DateTime finishedAt,
      required Map<int, int> answers,
      String testId = '1001',
    }) {
      return db.saveAttempt(TestAttempt(
        id: id,
        userId: user.id,
        testId: testId,
        testName: 'Test demo',
        finishedAt: finishedAt,
        durationSeconds: 60,
        netScore: 5,
        percentScore: 50,
        answers: answers,
        examSimulation: false,
        errorFormat: 100,
      ));
    }

    test('un acierto no se exporta y un fallo sí', () async {
      final at = DateTime.parse('2026-08-20T12:00:00');
      await saveAttempt(
        id: 'att-mix',
        finishedAt: at,
        answers: const {0: 2, 1: 2},
      );

      final result = await collector.collect(userId: user.id, range: rangeAround(at));
      expect(result.items, hasLength(1));
      expect(result.items.single.questionIndex, 0);
      expect(result.items.single.userAnswer, 2);
      expect(result.items.single.correctAnswer, 1);
      expect(result.items.single.lawCode, 'CE');
      expect(result.items.single.lawName, 'Constitución');
      expect(result.items.single.titleName, 'Derechos fundamentales');
    });

    test('el rango de fechas excluye intentos antiguos', () async {
      await saveAttempt(
        id: 'att-old',
        finishedAt: DateTime.parse('2026-08-01T12:00:00'),
        answers: const {0: 2},
      );
      await saveAttempt(
        id: 'att-new',
        finishedAt: DateTime.parse('2026-08-20T12:00:00'),
        answers: const {0: 3},
      );

      final result = await collector.collect(
        userId: user.id,
        range: FailedQuestionsRange(
          from: DateTime.parse('2026-08-19T00:00:00'),
          to: DateTime.parse('2026-08-21T00:00:00'),
          preset: FailedQuestionsPreset.custom,
        ),
      );
      expect(result.items, hasLength(1));
      expect(result.items.single.userAnswer, 3);
    });

    test('si la misma pregunta se falla dos veces, queda el más reciente', () async {
      await saveAttempt(
        id: 'att-first',
        finishedAt: DateTime.parse('2026-08-20T10:00:00'),
        answers: const {0: 2},
      );
      await saveAttempt(
        id: 'att-later',
        finishedAt: DateTime.parse('2026-08-20T18:00:00'),
        answers: const {0: 4},
      );

      final result = await collector.collect(
        userId: user.id,
        range: rangeAround(DateTime.parse('2026-08-20T12:00:00')),
      );
      expect(result.items, hasLength(1));
      expect(result.items.single.userAnswer, 4);
      expect(result.items.single.failedAt, DateTime.parse('2026-08-20T18:00:00'));
    });

    test('omite intentos de tests sintéticos', () async {
      await saveAttempt(
        id: 'att-synth',
        finishedAt: DateTime.parse('2026-08-20T12:00:00'),
        answers: const {0: 2},
        testId: 'reinforcement_random_abc',
      );
      final result = await collector.collect(
        userId: user.id,
        range: rangeAround(DateTime.parse('2026-08-20T12:00:00')),
      );
      expect(result.items, isEmpty);
    });
  });

  group('FailedQuestionsHtmlReport', () {
    test('incluye enunciado, respuestas, aclaración y ley', () {
      const report = FailedQuestionsHtmlReport();
      final html = report.build(
        userName: 'Ana',
        range: FailedQuestionsRange(
          from: DateTime(2026, 8, 20, 10),
          to: DateTime(2026, 8, 20, 18),
          preset: FailedQuestionsPreset.lastDay,
        ),
        skippedMissingTests: 0,
        generatedAt: DateTime(2026, 8, 25, 14, 30),
        items: [
          FailedQuestionItem(
            testId: '1001',
            testName: 'Test demo',
            questionIndex: 0,
            question: const Question(
              order: 1,
              text: '¿Quién ostenta la soberanía?',
              answers: ['El Rey', 'El pueblo', 'Las Cortes', 'El Gobierno'],
              solution: 2,
              clarificationHtml: 'Artículo 1.2 CE',
            ),
            userAnswer: 1,
            failedAt: DateTime(2026, 8, 20, 12),
            lawCode: 'CE',
            lawName: 'Constitución',
            titleName: 'Derechos fundamentales',
          ),
        ],
      );

      expect(html, contains('¿Quién ostenta la soberanía?'));
      expect(html, contains('El Rey'));
      expect(html, contains('El pueblo'));
      expect(html, contains('Tu respuesta'));
      expect(html, contains('Correcta'));
      expect(html, contains('Artículo 1.2 CE'));
      expect(html, contains('CE · Constitución'));
      expect(html, contains('Derechos fundamentales'));
      expect(html, contains('Ana'));
      expect(html, contains('<title>OpoTest · Preguntas falladas · Ana · 2026-08-25_14-30</title>'));
    });
  });
}
