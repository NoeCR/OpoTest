import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/features/random_tests/application/strategies/reinforcement_random_test_strategy.dart';
import 'package:testea_local/features/random_tests/domain/random_test_mode.dart';
import 'package:testea_local/models/local_user.dart';

import '../../helpers/database_helper.dart';
import 'random_test_context_helper.dart';

void main() {
  group('ReinforcementRandomTestStrategy', () {
    final strategy = ReinforcementRandomTestStrategy();
    late LocalUser user;

    setUp(() async {
      final setup = await setUpRandomTestContext();
      user = setup.user;
    });

    tearDown(tearDownTestDatabase);

    test('agrupa preguntas falladas de intentos recientes', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5040', questionCount: 4));
      await setup.db.saveAttempt(TestAttempt(
        id: 'att-reinforce',
        userId: user.id,
        testId: '5040',
        testName: 'Fallos',
        finishedAt: DateTime.parse('2026-08-21T10:00:00'),
        durationSeconds: 90,
        netScore: 5,
        percentScore: 50,
        answers: const {0: 2, 1: 1, 2: 3, 3: 4},
        examSimulation: false,
        errorFormat: 100,
      ));

      final pick = await strategy.pick(setup.context, user.id);
      expect(pick.isEmpty, isFalse);
      expect(pick.mixedTest?.type, 'reinforcement');
      expect(pick.mixedTest?.questions.length, 2);
    });

    test('vacío sin fallos recientes', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5041', questionCount: 2));
      await setup.db.saveAttempt(TestAttempt(
        id: 'att-perfect',
        userId: user.id,
        testId: '5041',
        testName: 'Perfecto',
        finishedAt: DateTime.parse('2026-08-21T11:00:00'),
        durationSeconds: 60,
        netScore: 10,
        percentScore: 100,
        answers: const {0: 1, 1: 2},
        examSimulation: false,
        errorFormat: 100,
      ));

      final pick = await strategy.pick(setup.context, user.id);
      expect(pick.isEmpty, isTrue);
      expect(pick.emptyMessage, RandomTestMode.reinforcement.emptyHint);
    });
  });
}
