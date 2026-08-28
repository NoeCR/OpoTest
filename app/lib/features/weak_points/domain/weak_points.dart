import '../../../models/test_stats.dart';
import '../../random_tests/domain/random_test_constants.dart';

enum WeakPointsScope { laws, titles }

enum WeakPointsSort { weakest, last, average, attempts }

extension WeakPointsScopeLabel on WeakPointsScope {
  String get label => switch (this) {
        WeakPointsScope.laws => 'Leyes',
        WeakPointsScope.titles => 'Títulos',
      };
}

extension WeakPointsSortLabel on WeakPointsSort {
  String get label => switch (this) {
        WeakPointsSort.weakest => 'Flojo',
        WeakPointsSort.last => 'Último',
        WeakPointsSort.average => 'Media',
        WeakPointsSort.attempts => 'Intentos',
      };
}

class TopicAttemptPoint {
  const TopicAttemptPoint({
    required this.testId,
    required this.lawId,
    required this.percent,
    required this.finishedAt,
    this.titleId,
  });

  final String testId;
  final String lawId;
  final String? titleId;
  final double percent;
  final DateTime finishedAt;
}

class WeakTopic {
  const WeakTopic({
    required this.id,
    required this.scope,
    required this.title,
    required this.stats,
    required this.lawId,
    this.subtitle,
    this.lawCode,
    this.lawName,
    this.titleId,
  });

  final String id;
  final WeakPointsScope scope;
  final String title;
  final String? subtitle;
  final TestStats stats;
  final String lawId;
  final String? lawCode;
  final String? lawName;
  final String? titleId;
}

class LawLabel {
  const LawLabel({required this.code, required this.name});
  final String code;
  final String name;
}

class TitleLabel {
  const TitleLabel({required this.lawId, required this.code, required this.name});
  final String lawId;
  final String code;
  final String name;
}

TestStats statsFromChronologicalPercents(List<double> percents) {
  if (percents.isEmpty) return const TestStats();
  final avg = percents.reduce((a, b) => a + b) / percents.length;
  final best = percents.reduce((a, b) => a > b ? a : b);
  return TestStats(
    avgPercent: avg,
    bestPercent: best,
    lastPercent: percents.last,
    attempts: percents.length,
  );
}

List<TopicAttemptPoint> officialAttemptPoints(Iterable<TopicAttemptPoint> points) {
  return [
    for (final point in points)
      if (point.lawId.isNotEmpty &&
          !RandomTestConstants.isSyntheticAttemptTestId(point.testId))
        point,
  ];
}

List<WeakTopic> buildWeakTopics({
  required WeakPointsScope scope,
  required Iterable<TopicAttemptPoint> attempts,
  required Map<String, LawLabel> laws,
  required Map<String, TitleLabel> titles,
}) {
  final official = officialAttemptPoints(attempts);
  official.sort((a, b) => a.finishedAt.compareTo(b.finishedAt));

  final grouped = <String, List<double>>{};
  for (final point in official) {
    final key = scope == WeakPointsScope.laws ? point.lawId : (point.titleId ?? '');
    if (key.isEmpty) continue;
    (grouped[key] ??= []).add(point.percent);
  }

  final topics = <WeakTopic>[];
  for (final entry in grouped.entries) {
    if (scope == WeakPointsScope.laws) {
      final law = laws[entry.key];
      if (law == null) continue;
      final title = law.code.isNotEmpty ? law.code : law.name;
      topics.add(
        WeakTopic(
          id: entry.key,
          scope: scope,
          title: title,
          subtitle: law.name.isNotEmpty && law.name != title ? law.name : null,
          stats: statsFromChronologicalPercents(entry.value),
          lawId: entry.key,
          lawCode: law.code,
          lawName: law.name,
        ),
      );
    } else {
      final titleRow = titles[entry.key];
      if (titleRow == null) continue;
      final law = laws[titleRow.lawId];
      final name = titleRow.name.isNotEmpty ? titleRow.name : titleRow.code;
      topics.add(
        WeakTopic(
          id: entry.key,
          scope: scope,
          title: name,
          subtitle: law == null
              ? null
              : (law.code.isNotEmpty ? '${law.code} · ${law.name}' : law.name),
          stats: statsFromChronologicalPercents(entry.value),
          lawId: titleRow.lawId,
          lawCode: law?.code,
          lawName: law?.name,
          titleId: entry.key,
        ),
      );
    }
  }
  return topics;
}

void sortWeakTopics(List<WeakTopic> topics, WeakPointsSort sort) {
  topics.sort((a, b) {
    switch (sort) {
      case WeakPointsSort.weakest:
        final byLast = _nullsLast(a.stats.lastPercent, b.stats.lastPercent);
        if (byLast != 0) return byLast;
        final byAvg = _nullsLast(a.stats.avgPercent, b.stats.avgPercent);
        if (byAvg != 0) return byAvg;
        return b.stats.attempts.compareTo(a.stats.attempts);
      case WeakPointsSort.last:
        return _nullsLast(a.stats.lastPercent, b.stats.lastPercent);
      case WeakPointsSort.average:
        return _nullsLast(a.stats.avgPercent, b.stats.avgPercent);
      case WeakPointsSort.attempts:
        final byAttempts = b.stats.attempts.compareTo(a.stats.attempts);
        if (byAttempts != 0) return byAttempts;
        return _nullsLast(a.stats.lastPercent, b.stats.lastPercent);
    }
  });
}

int _nullsLast(double? a, double? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
