import '../domain/random_test_mode.dart';
import '../domain/random_test_pick.dart';
import '../domain/random_test_strategy.dart';
import 'random_test_context.dart';
import 'strategies/classic_random_test_strategy.dart';
import 'strategies/marked_review_random_test_strategy.dart';
import 'strategies/mixed_random_test_strategy.dart';
import 'strategies/most_errors_random_test_strategy.dart';
import 'strategies/own_random_test_strategy.dart';
import 'strategies/practiced_random_test_strategy.dart';
import 'strategies/refresh_random_test_strategy.dart';
import 'strategies/reinforcement_random_test_strategy.dart';

/// Registro mode → estrategia (patrón Strategy + Registry).
class RandomTestStrategyRegistry {
  RandomTestStrategyRegistry(this._context)
      : _strategies = {
          for (final strategy in _allStrategies) strategy.mode: strategy,
        };

  static final _allStrategies = <RandomTestStrategy>[
    ClassicRandomTestStrategy(),
    OwnRandomTestStrategy(),
    PracticedRandomTestStrategy(),
    RefreshRandomTestStrategy(),
    MostErrorsRandomTestStrategy(),
    MixedRandomTestStrategy(),
    ReinforcementRandomTestStrategy(),
    MarkedReviewRandomTestStrategy(),
  ];

  final RandomTestContext _context;
  final Map<RandomTestMode, RandomTestStrategy> _strategies;

  Future<RandomTestPick> pick({
    required RandomTestMode mode,
    required String userId,
  }) {
    final strategy = _strategies[mode];
    if (strategy == null) {
      throw StateError('Estrategia no registrada para $mode');
    }
    return strategy.pick(_context, userId);
  }
}
