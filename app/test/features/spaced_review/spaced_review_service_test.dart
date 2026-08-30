import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/random_tests/application/synthetic_test_builder.dart';
import 'package:opotest/features/spaced_review/application/spaced_review_service.dart';
import 'package:opotest/models/local_user.dart';
import 'package:opotest/models/question.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('SpacedReviewService', () {
    late AppDatabase db;
    late SpacedReviewService service;
    late LocalUser user;
    final now = DateTime(2026, 8, 28, 12);

    setUp(() async {
      db = await setUpTestDatabase();
      service = SpacedReviewService(db);
      user = LocalUser(
        id: 'user-review',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
      await db.upsertOfficialTest(sampleTestJson(id: '1001', questionCount: 2));
    });

    tearDown(tearDownTestDatabase);

    test('un fallo programa el repaso para el día siguiente', () async {
      final test = (await db.getTest('1001'))!;
      await service.applyFromTest(
        userId: user.id,
        test: test,
        answers: const {0: 2, 1: 2},
        at: now,
      );

      final dueTomorrow = await db.countDueQuestionReviews(user.id, DateTime(2026, 8, 29));
      expect(dueTomorrow, 1);
      expect(await db.countDueQuestionReviews(user.id, now), 0);
    });

    test('un acierto en repaso alarga el intervalo', () async {
      final test = (await db.getTest('1001'))!;
      await service.applyFromTest(
        userId: user.id,
        test: test,
        answers: const {0: 2},
        at: now,
      );
      await service.applyFromTest(
        userId: user.id,
        test: test,
        answers: const {0: 1},
        at: DateTime(2026, 8, 29, 10),
      );

      final states = await db.questionReviewsForUser(user.id);
      expect(states, hasLength(1));
      expect(states.single.box, 2);
      expect(states.single.nextDue, DateTime(2026, 9, 1));
      expect(await db.countDueQuestionReviews(user.id, DateTime(2026, 8, 30)), 0);
    });

    test('usa el origen de las preguntas sintéticas', () async {
      final cloned = TestDefinition(
        id: 'reinforcement_random_1',
        name: 'Refuerzo',
        type: 'reinforcement',
        questions: [
          cloneQuestion(
            (await db.getTest('1001'))!.questions.first,
            order: 1,
            sourceTestId: '1001',
            sourceQuestionIndex: 0,
          ),
        ],
      );
      await service.applyFromTest(
        userId: user.id,
        test: cloned,
        answers: const {0: 2},
        at: now,
      );

      final states = await db.questionReviewsForUser(user.id);
      expect(states.single.testId, '1001');
      expect(states.single.questionIndex, 0);
    });

    test('un acierto sin estado previo no crea fila', () async {
      final test = (await db.getTest('1001'))!;
      await service.applyFromTest(
        userId: user.id,
        test: test,
        answers: const {0: 1},
        at: now,
      );

      expect(await db.questionReviewsForUser(user.id), isEmpty);
    });
  });
}
