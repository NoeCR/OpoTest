import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';

class ClassicRandomTestStrategy implements RandomTestStrategy {
  @override
  RandomTestMode get mode => RandomTestMode.classic;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final ids = await context.db.getAllTestIds();
    if (ids.isEmpty) return context.emptyFor(mode);
    return context.pickTestId(ids[context.random.nextInt(ids.length)]);
  }
}
