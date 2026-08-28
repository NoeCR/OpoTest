import '../../../database/app_database.dart';
import '../../failed_questions_export/application/failed_questions_collector.dart';
import '../../failed_questions_export/domain/failed_questions_range.dart';
import '../../random_tests/domain/random_test_constants.dart';
import '../domain/daily_focus.dart';

class DailyFocusService {
  DailyFocusService(this._db, this._fails);

  final AppDatabase _db;
  final FailedQuestionsCollector _fails;

  Future<DailyFocusPlan> planFor({
    required String userId,
    required bool contentReady,
    DateTime? now,
  }) async {
    final snapshot = await snapshotFor(
      userId: userId,
      contentReady: contentReady,
      now: now,
    );
    return buildDailyFocus(snapshot);
  }

  Future<DailyFocusSnapshot> snapshotFor({
    required String userId,
    required bool contentReady,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final lastMarkedReviewAt = await _lastMarkedReviewAt(userId);
    final marked = await _db.markedQuestionsForUser(userId);
    final recentMarkedCount = marked.where((m) {
      if (RandomTestConstants.isSyntheticAttemptTestId(m.testId)) return false;
      return countsForMarkedFocus(
        markedAt: m.markedAt,
        now: at,
        lastMarkedReviewAt: lastMarkedReviewAt,
      );
    }).length;

    final fails = await _fails.collect(
      userId: userId,
      range: FailedQuestionsRange.last7Days(now: at),
    );

    final weakest = await _weakestTest(userId);
    final lastAttempt = await _lastOfficialAttempt(userId);

    return DailyFocusSnapshot(
      contentReady: contentReady,
      recentMarkedCount: recentMarkedCount,
      recentFailCount: fails.items.length,
      weakest: weakest,
      lastAttempt: lastAttempt,
    );
  }

  Future<DateTime?> _lastMarkedReviewAt(String userId) async {
    final attempts = await _db.attemptsForUser(userId);
    for (final row in attempts) {
      final testId = row['test_id'] as String? ?? '';
      if (!testId.startsWith('review_random')) continue;
      return DateTime.tryParse(row['finished_at'] as String? ?? '');
    }
    return null;
  }

  Future<WeakTestHint?> _weakestTest(String userId) async {
    final ids = (await _db.attemptedTestIds(userId))
        .where((id) => !RandomTestConstants.isSyntheticAttemptTestId(id))
        .toList();
    if (ids.isEmpty) return null;

    final stats = await _db.statsForTests(userId, ids);
    final hints = <WeakTestHint>[];
    for (final id in ids) {
      final stat = stats[id];
      final last = stat?.lastPercent;
      if (last == null) continue;
      final test = await _db.getTest(id);
      if (test == null) continue;
      hints.add(
        WeakTestHint(
          testId: id,
          testName: test.name,
          lastPercent: last,
          attempts: stat?.attempts ?? 0,
        ),
      );
    }
    return pickWeakestTest(hints);
  }

  Future<LastAttemptHint?> _lastOfficialAttempt(String userId) async {
    final last = await _db.getLastAttempt(userId);
    if (last == null) return null;
    final testId = last['test_id'] as String? ?? '';
    if (testId.isEmpty || RandomTestConstants.isSyntheticAttemptTestId(testId)) {
      return null;
    }
    if (await _db.getTest(testId) == null) return null;
    return LastAttemptHint(
      testId: testId,
      testName: last['test_name'] as String? ?? 'Test',
    );
  }
}
