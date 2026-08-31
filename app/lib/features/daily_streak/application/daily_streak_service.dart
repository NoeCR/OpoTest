import '../../../database/app_database.dart';
import '../../../models/local_user.dart';
import '../domain/daily_streak.dart';

class DailyStreakService {
  DailyStreakService(this._db);

  final AppDatabase _db;

  Future<DailyStreakSnapshot> snapshotFor({
    required String userId,
    required int dailyGoal,
    DateTime? now,
  }) async {
    final rows = await _db.attemptsForUser(userId);
    final points = rows.map((row) {
      final attempt = TestAttempt.fromMap(row);
      return DailyAttemptPoint(
        finishedAt: attempt.finishedAt,
        answeredCount: attempt.answers.length,
      );
    }).toList();
    return buildDailyStreak(
      attempts: points,
      dailyGoal: dailyGoal,
      now: now ?? DateTime.now(),
    );
  }
}
