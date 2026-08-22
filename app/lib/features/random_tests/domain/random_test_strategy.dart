import 'random_test_mode.dart';
import 'random_test_pick.dart';
import '../application/random_test_context.dart';

/// Estrategia de selección para un modo concreto de test aleatorio.
abstract class RandomTestStrategy {
  RandomTestMode get mode;

  Future<RandomTestPick> pick(RandomTestContext context, String userId);
}
