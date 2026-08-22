import 'dart:math';

import '../../domain/random_test_constants.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';

class RefreshRandomTestStrategy implements RandomTestStrategy {
  @override
  RandomTestMode get mode => RandomTestMode.refresh;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final lastByTest = await context.lastAttemptsByTest(userId);
    if (lastByTest.isEmpty) return context.emptyFor(mode);

    final now = DateTime.now();
    final scored = <String, double>{};
    for (final entry in lastByTest.entries) {
      final attempt = entry.value;
      final days = now.difference(attempt.finishedAt).inDays.toDouble();
      final durationBoost = attempt.durationSeconds / 60.0;
      scored[entry.key] = days + durationBoost * 0.15;
    }

    final candidates = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = candidates.take(min(8, candidates.length)).toList();
    final stale = top.where((e) => e.value >= RandomTestConstants.refreshMinDays).toList();
    final pool = stale.isNotEmpty ? stale : top;

    return context.pickTestId(
      context.pickWeightedKey(pool.map((e) => MapEntry(e.key, e.value)).toList()),
    );
  }
}
