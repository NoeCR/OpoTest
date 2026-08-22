import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';

class PracticedRandomTestStrategy implements RandomTestStrategy {
  @override
  RandomTestMode get mode => RandomTestMode.practiced;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final attempted = await context.db.attemptedTestIds(userId);
    final official = await context.db.getAllTestIds();
    final pool = official.where(attempted.contains).toList();
    if (pool.isEmpty) return context.emptyFor(mode);
    return context.pickTestId(pool[context.random.nextInt(pool.length)]);
  }
}
