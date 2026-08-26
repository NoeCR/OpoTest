import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/random_tests/application/random_test_service.dart';
import 'package:opotest/features/random_tests/application/strategies/classic_random_test_strategy.dart';
import 'package:opotest/features/random_tests/application/strategies/marked_review_random_test_strategy.dart';
import 'package:opotest/features/random_tests/application/strategies/mixed_random_test_strategy.dart';
import 'package:opotest/features/random_tests/application/strategies/most_errors_random_test_strategy.dart';
import 'package:opotest/features/random_tests/application/strategies/own_random_test_strategy.dart';
import 'package:opotest/features/random_tests/application/strategies/practiced_random_test_strategy.dart';
import 'package:opotest/features/random_tests/application/strategies/reinforcement_random_test_strategy.dart';
import 'package:opotest/features/random_tests/domain/random_test_mode.dart';
import 'package:opotest/models/local_user.dart';

import '../../helpers/database_helper.dart';
import 'random_test_context_helper.dart';

void main() {
  group('RandomTestService', () {
    late RandomTestService service;
    late LocalUser user;

    setUp(() async {
      final setup = await setUpRandomTestContext();
      user = setup.user;
      service = RandomTestService(setup.db);
    });

    tearDown(tearDownTestDatabase);

    test('delega en el registro para classic', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      service = RandomTestService(setup.db);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5001'));
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5002', lawId: '11'));

      final pick = await service.pick(mode: RandomTestMode.classic, userId: user.id);
      expect(pick.isEmpty, isFalse);
      expect(['5001', '5002'], contains(pick.testId));
    });

    test('delega en el registro para own', () async {
      final setup = await setUpRandomTestContext(userId: user.id);
      service = RandomTestService(setup.db);
      await setup.db.upsertOfficialTest(sampleTestJson(id: '5001'));
      await setup.db.upsertCustomTest(sampleTestJson(id: 'custom_a'));

      final pick = await service.pick(mode: RandomTestMode.own, userId: user.id);
      expect(pick.isEmpty, isFalse);
      expect(pick.testId, 'custom_a');
    });

    test('registra una estrategia por modo', () {
      expect(ClassicRandomTestStrategy().mode, RandomTestMode.classic);
      expect(OwnRandomTestStrategy().mode, RandomTestMode.own);
      expect(PracticedRandomTestStrategy().mode, RandomTestMode.practiced);
      expect(MostErrorsRandomTestStrategy().mode, RandomTestMode.mostErrors);
      expect(MixedRandomTestStrategy().mode, RandomTestMode.mixed);
      expect(ReinforcementRandomTestStrategy().mode, RandomTestMode.reinforcement);
      expect(MarkedReviewRandomTestStrategy().mode, RandomTestMode.markedReview);
    });
  });
}
