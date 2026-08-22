import 'dart:math';

import '../../../database/app_database.dart';
import '../domain/random_test_constants.dart';
import '../domain/random_test_mode.dart';
import '../domain/random_test_pick.dart';
import 'random_test_context.dart';
import 'random_test_strategy_registry.dart';

/// Fachada de aplicación: delega en el registro de estrategias.
class RandomTestService {
  RandomTestService(AppDatabase db, {Random? random})
      : _registry = RandomTestStrategyRegistry(RandomTestContext(db, random: random));

  final RandomTestStrategyRegistry _registry;

  static const mixedQuestionCount = RandomTestConstants.mixedQuestionCount;
  static const refreshMinDays = RandomTestConstants.refreshMinDays;
  static const reinforcementMaxAttempts = RandomTestConstants.reinforcementMaxAttempts;
  static const reinforcementQuestionCap = RandomTestConstants.reinforcementQuestionCap;

  static bool isSyntheticAttemptTestId(String testId) =>
      RandomTestConstants.isSyntheticAttemptTestId(testId);

  Future<RandomTestPick> pick({
    required RandomTestMode mode,
    required String userId,
  }) {
    return _registry.pick(mode: mode, userId: userId);
  }
}
