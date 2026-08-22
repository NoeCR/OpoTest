import 'dart:math';

import '../../../database/app_database.dart';
import '../../../models/local_user.dart';
import '../domain/random_test_constants.dart';
import '../domain/random_test_mode.dart';
import '../domain/random_test_pick.dart';

/// Dependencias compartidas por todas las estrategias.
class RandomTestContext {
  RandomTestContext(this.db, {Random? random}) : random = random ?? Random();

  final AppDatabase db;
  final Random random;

  RandomTestPick emptyFor(RandomTestMode mode) => RandomTestPick.empty(mode.emptyHint);

  RandomTestPick pickTestId(String testId) => RandomTestPick.test(testId);

  Future<Map<String, TestAttempt>> lastAttemptsByTest(String userId) async {
    final attempts = await db.attemptsForUserModel(userId);
    final map = <String, TestAttempt>{};
    for (final attempt in attempts) {
      if (RandomTestConstants.isSyntheticAttemptTestId(attempt.testId)) continue;
      map.putIfAbsent(attempt.testId, () => attempt);
    }
    return map;
  }

  String pickWeightedKey(List<MapEntry<String, double>> weighted) {
    if (weighted.isEmpty) throw StateError('weighted pool vacío');
    final total = weighted.fold<double>(0, (sum, e) => sum + e.value);
    var roll = random.nextDouble() * total;
    for (final entry in weighted) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return weighted.last.key;
  }
}
