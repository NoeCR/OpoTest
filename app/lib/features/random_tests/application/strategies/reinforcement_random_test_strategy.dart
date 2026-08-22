import '../../../../models/question.dart';
import '../../domain/random_test_constants.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';
import '../synthetic_test_builder.dart';

class ReinforcementRandomTestStrategy implements RandomTestStrategy {
  ReinforcementRandomTestStrategy({SyntheticTestBuilder? builder})
      : _builder = builder ?? SyntheticTestBuilder();

  final SyntheticTestBuilder _builder;

  @override
  RandomTestMode get mode => RandomTestMode.reinforcement;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final attempts = await context.db.attemptsForUserModel(userId);
    final recent = attempts
        .where((attempt) => !RandomTestConstants.isSyntheticAttemptTestId(attempt.testId))
        .take(RandomTestConstants.reinforcementMaxAttempts)
        .toList();

    if (recent.isEmpty) return context.emptyFor(mode);

    final seen = <String>{};
    final failed = <Question>[];
    final testCache = <String, TestDefinition?>{};

    for (final attempt in recent) {
      final test = testCache[attempt.testId] ??= await context.db.getTest(attempt.testId);
      if (test == null) continue;

      for (var i = 0; i < test.questions.length; i++) {
        final answer = attempt.answers[i];
        if (answer == null || answer == 0) continue;
        if (answer == test.questions[i].solution) continue;

        final key = '${attempt.testId}:$i';
        if (!seen.add(key)) continue;
        failed.add(cloneQuestion(test.questions[i], order: failed.length + 1));
      }
    }

    if (failed.isEmpty) return context.emptyFor(mode);

    failed.shuffle(context.random);
    final selected = renumberQuestions(
      failed.take(RandomTestConstants.reinforcementQuestionCap).toList(),
    );

    return _builder.build(
      idPrefix: 'reinforcement_random',
      namePrefix: 'Test de refuerzo',
      type: 'reinforcement',
      questions: selected,
    );
  }
}
