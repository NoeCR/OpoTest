import '../../../database/app_database.dart';
import '../../../models/local_user.dart';
import '../domain/score_trend.dart';

class ScoreTrendService {
  ScoreTrendService(this._db);

  final AppDatabase _db;

  Future<ScoreTrend> forUser({
    required String userId,
    DateTime? now,
    int maxBars = 15,
  }) async {
    final rows = await _db.attemptsForUser(userId);
    final points = rows.map((row) {
      final attempt = TestAttempt.fromMap(row);
      return AttemptScorePoint(
        finishedAt: attempt.finishedAt,
        percent: attempt.percentScore,
        testId: attempt.testId,
      );
    }).toList();
    return buildScoreTrend(
      attempts: points,
      now: now ?? DateTime.now(),
      maxBars: maxBars,
    );
  }
}
