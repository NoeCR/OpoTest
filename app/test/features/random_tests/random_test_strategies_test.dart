import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/features/random_tests/application/strategies/classic_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/application/strategies/marked_review_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/application/strategies/mixed_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/application/strategies/most_errors_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/application/strategies/practiced_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/application/strategies/reinforcement_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/domain/random_test_mode.dart';
import 'package:testea_local/models/local_user.dart';

import '../../helpers/database_helper.dart';
import 'random_test_context_helper.dart';

void main() {
  group('Random test strategies', () {
    late LocalUser user;

    setUp(() async {
      final setup = await setUpRandomTestContext();
      user = setup.user;
    });

    tearDown(tearDownTestDatabase);

    test('classic elige un test cuando hay temario', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5001'));
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5002', lawId: '11'));

      final pick = await ClassicRandomTestStrategy().pick(setup.context, user.id);
      expect(pick.isEmpty, isFalse);
      expect(['5001', '5002'], contains(pick.testId));
    });

    test('practiced solo elige tests ya intentados', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5010'));
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5011', lawId: '11'));
      await setup.db.saveAttempt(TestAttempt(
        id: 'att-practiced',
        userId: user.id,
        testId: '5010',
        testName: 'Hecho',
        finishedAt: DateTime.parse('2026-08-01T10:00:00'),
        durationSeconds: 120,
        netScore: 8,
        percentScore: 80,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 100,
      ));

      for (var i = 0; i < 8; i++) {
        final pick = await PracticedRandomTestStrategy().pick(setup.context, user.id);
        expect(pick.testId, '5010');
      }
    });

    test('mostErrors prioriza tests con fallos recientes', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5020', questionCount: 4));
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5021', lawId: '11', questionCount: 4));
      await setup.db.saveAttempt(TestAttempt(
        id: 'att-good',
        userId: user.id,
        testId: '5020',
        testName: 'Bueno',
        finishedAt: DateTime.parse('2026-08-19T10:00:00'),
        durationSeconds: 60,
        netScore: 10,
        percentScore: 100,
        answers: const {0: 1, 1: 2, 2: 3, 3: 4},
        examSimulation: false,
        errorFormat: 100,
      ));
      await setup.db.saveAttempt(TestAttempt(
        id: 'att-bad',
        userId: user.id,
        testId: '5021',
        testName: 'Malo',
        finishedAt: DateTime.parse('2026-08-20T10:00:00'),
        durationSeconds: 60,
        netScore: 2.5,
        percentScore: 25,
        answers: const {0: 2, 1: 1, 2: 1, 3: 1},
        examSimulation: false,
        errorFormat: 100,
      ));

      final pick = await MostErrorsRandomTestStrategy().pick(setup.context, user.id);
      expect(pick.testId, '5021');
    });

    test('mixed genera test sintético con preguntas', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5030', lawId: '20'));
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5031', lawId: '21'));

      final pick = await MixedRandomTestStrategy().pick(setup.context, user.id);
      expect(pick.isEmpty, isFalse);
      expect(pick.mixedTest, isNotNull);
      expect(pick.mixedTest!.questions, isNotEmpty);
      expect(pick.mixedTest!.type, 'mixed');
    });

    test('markedReview genera test con preguntas marcadas', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5050', questionCount: 3));
      await setup.db.toggleMarkedQuestion(userId: user.id, testId: '5050', questionIndex: 0);
      await setup.db.toggleMarkedQuestion(userId: user.id, testId: '5050', questionIndex: 2);

      final pick = await MarkedReviewRandomTestStrategy().pick(setup.context, user.id);
      expect(pick.isEmpty, isFalse);
      expect(pick.mixedTest?.type, 'review');
      expect(pick.mixedTest?.questions.length, 2);
    });

    test('markedReview vacío sin preguntas marcadas', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      final pick = await MarkedReviewRandomTestStrategy().pick(setup.context, user.id);
      expect(pick.isEmpty, isTrue);
      expect(pick.emptyMessage, RandomTestMode.markedReview.emptyHint);
    });
  });
}
