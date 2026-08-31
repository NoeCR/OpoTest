import '../../random_tests/domain/random_test_constants.dart';

DateTime _calendarDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class AttemptScorePoint {
  const AttemptScorePoint({
    required this.finishedAt,
    required this.percent,
    required this.testId,
  });

  final DateTime finishedAt;
  final double percent;
  final String testId;
}

class ScoreTrendBar {
  const ScoreTrendBar({
    required this.percent,
    required this.finishedAt,
  });

  final double percent;
  final DateTime finishedAt;
}

class ScoreTrend {
  const ScoreTrend({
    required this.thisWeekAverage,
    required this.previousWeekAverage,
    required this.thisWeekCount,
    required this.previousWeekCount,
    required this.recentBars,
  });

  final double? thisWeekAverage;
  final double? previousWeekAverage;
  final int thisWeekCount;
  final int previousWeekCount;
  final List<ScoreTrendBar> recentBars;

  bool get isEmpty =>
      thisWeekCount == 0 && previousWeekCount == 0 && recentBars.isEmpty;

  /// Diferencia esta semana menos la anterior, o null si falta alguna.
  double? get weekDelta {
    final current = thisWeekAverage;
    final previous = previousWeekAverage;
    if (current == null || previous == null) return null;
    return current - previous;
  }
}

DateTime weekStartMonday(DateTime value) {
  final day = _calendarDay(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

double? _average(List<double> values) {
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Tendencia de notas oficiales (sin tests sintéticos).
/// [recentBars] son los últimos [maxBars] intentos, de más antiguo a más reciente.
ScoreTrend buildScoreTrend({
  required List<AttemptScorePoint> attempts,
  required DateTime now,
  int maxBars = 15,
}) {
  final official = [
    for (final a in attempts)
      if (!RandomTestConstants.isSyntheticAttemptTestId(a.testId)) a,
  ];
  official.sort((a, b) => a.finishedAt.compareTo(b.finishedAt));

  final thisWeek = weekStartMonday(now);
  final previousWeek = thisWeek.subtract(const Duration(days: 7));
  final thisPercents = <double>[];
  final prevPercents = <double>[];
  for (final a in official) {
    final start = weekStartMonday(a.finishedAt);
    if (start == thisWeek) {
      thisPercents.add(a.percent);
    } else if (start == previousWeek) {
      prevPercents.add(a.percent);
    }
  }

  final recent = official.length <= maxBars ? official : official.sublist(official.length - maxBars);

  return ScoreTrend(
    thisWeekAverage: _average(thisPercents),
    previousWeekAverage: _average(prevPercents),
    thisWeekCount: thisPercents.length,
    previousWeekCount: prevPercents.length,
    recentBars: [
      for (final a in recent)
        ScoreTrendBar(percent: a.percent, finishedAt: a.finishedAt),
    ],
  );
}
