import '../../../database/app_database.dart';
import '../domain/weak_points.dart';

class WeakPointsService {
  WeakPointsService(this._db);

  final AppDatabase _db;

  Future<List<WeakTopic>> topicsFor({
    required String userId,
    required WeakPointsScope scope,
    WeakPointsSort sort = WeakPointsSort.weakest,
  }) async {
    final rows = await _db.officialAttemptPoints(userId);
    final attempts = <TopicAttemptPoint>[];
    for (final row in rows) {
      final testId = row['test_id']?.toString() ?? '';
      final lawId = row['law_id']?.toString() ?? '';
      final finished = DateTime.tryParse(row['finished_at'] as String? ?? '');
      if (testId.isEmpty || lawId.isEmpty || finished == null) continue;
      attempts.add(
        TopicAttemptPoint(
          testId: testId,
          lawId: lawId,
          titleId: row['title_id']?.toString(),
          percent: (row['percent_score'] as num?)?.toDouble() ?? 0,
          finishedAt: finished,
        ),
      );
    }

    final laws = <String, LawLabel>{};
    for (final row in await _db.getLaws()) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      laws[id] = LawLabel(
        code: row['code']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
      );
    }

    final titles = <String, TitleLabel>{};
    if (scope == WeakPointsScope.titles) {
      for (final row in await _db.titlesWithLaw()) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        titles[id] = TitleLabel(
          lawId: row['law_id']?.toString() ?? '',
          code: row['code']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
        );
      }
    }

    final topics = buildWeakTopics(
      scope: scope,
      attempts: attempts,
      laws: laws,
      titles: titles,
    );
    sortWeakTopics(topics, sort);
    return topics;
  }
}
