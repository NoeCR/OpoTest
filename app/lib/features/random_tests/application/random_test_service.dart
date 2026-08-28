import 'dart:math';

import '../../../database/app_database.dart';
import '../domain/official_paper_ref.dart';
import '../domain/random_test_constants.dart';
import '../domain/random_test_mode.dart';
import '../domain/random_test_pick.dart';
import 'random_test_context.dart';
import 'random_test_strategy_registry.dart';
import 'strategies/mixed_random_test_strategy.dart';

/// Fachada de aplicación: delega en el registro de estrategias.
class RandomTestService {
  RandomTestService(AppDatabase db, {Random? random})
      : this._(RandomTestContext(db, random: random));

  RandomTestService._(this._context)
      : _registry = RandomTestStrategyRegistry(_context);

  final RandomTestContext _context;
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

  Future<List<OfficialPaperRef>> listOfficialPapers() async {
    final meta = await _context.db.getOfficialTestsMeta(
      types: RandomTestConstants.simulacrumOfficialTypes,
    );
    return [
      for (final row in meta) OfficialPaperRef.fromMeta(id: row.id, name: row.name),
    ];
  }

  Future<RandomTestPick> pickSimulacrum({
    required String userId,
    int questionCount = RandomTestConstants.simulacrumDefaultQuestions,
    Set<String>? includedTestIds,
  }) {
    return MixedRandomTestStrategy(
      questionCount: questionCount,
      idPrefix: RandomTestConstants.simulacrumIdPrefix,
      namePrefix: 'Simulacro',
      type: 'simulacrum',
      emptyHint: 'No hay pruebas reales importadas para generar un simulacro.',
      allowedTypes: RandomTestConstants.simulacrumOfficialTypes,
      allowedTestIds: includedTestIds,
    ).pick(_context, userId);
  }
}
