import '../../../../services/test_scoring.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';

class MostErrorsRandomTestStrategy implements RandomTestStrategy {
  @override
  RandomTestMode get mode => RandomTestMode.mostErrors;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final lastByTest = await context.lastAttemptsByTest(userId);
    if (lastByTest.isEmpty) return context.emptyFor(mode);

    final weighted = <MapEntry<String, double>>[];
    for (final entry in lastByTest.entries) {
      final test = await context.db.getTest(entry.key);
      if (test == null) continue;
      final result = TestScoring.score(
        questions: test.questions,
        answers: entry.value.answers,
        errorFormat: entry.value.errorFormat,
      );
      if (result.incorrect > 0) {
        weighted.add(MapEntry(entry.key, result.incorrect.toDouble()));
      }
    }

    if (weighted.isEmpty) return context.emptyFor(mode);
    return context.pickTestId(context.pickWeightedKey(weighted));
  }
}
