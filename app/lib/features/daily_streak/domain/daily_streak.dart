/// Día de calendario local (sin hora) a partir de un instante.
DateTime calendarDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class DailyAttemptPoint {
  const DailyAttemptPoint({
    required this.finishedAt,
    required this.answeredCount,
  });

  final DateTime finishedAt;
  final int answeredCount;
}

class DailyStreakSnapshot {
  const DailyStreakSnapshot({
    required this.streakDays,
    required this.questionsToday,
    required this.testsToday,
    required this.dailyGoal,
  });

  final int streakDays;
  final int questionsToday;
  final int testsToday;
  final int dailyGoal;

  bool get goalMet => dailyGoal > 0 && questionsToday >= dailyGoal;

  double get progress {
    if (dailyGoal <= 0) return 0;
    final ratio = questionsToday / dailyGoal;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  String get streakLabel {
    if (streakDays <= 0) return 'Sin racha';
    if (streakDays == 1) return '1 día seguido';
    return '$streakDays días seguidos';
  }

  String get cupoLabel => '$questionsToday / $dailyGoal preguntas hoy';
}

/// Racha: días consecutivos con al menos un test terminado, anclada en hoy
/// o en ayer si hoy aún no hay intentos (el día no se ha perdido).
int streakDaysEndingNear(Set<DateTime> activeDays, DateTime now) {
  if (activeDays.isEmpty) return 0;
  final today = calendarDay(now);
  final yesterday = today.subtract(const Duration(days: 1));
  final DateTime start;
  if (activeDays.contains(today)) {
    start = today;
  } else if (activeDays.contains(yesterday)) {
    start = yesterday;
  } else {
    return 0;
  }
  var cursor = start;
  var count = 0;
  while (activeDays.contains(cursor)) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

DailyStreakSnapshot buildDailyStreak({
  required List<DailyAttemptPoint> attempts,
  required int dailyGoal,
  required DateTime now,
}) {
  final today = calendarDay(now);
  final days = <DateTime>{};
  var questionsToday = 0;
  var testsToday = 0;
  for (final attempt in attempts) {
    final day = calendarDay(attempt.finishedAt);
    days.add(day);
    if (day == today) {
      testsToday++;
      questionsToday += attempt.answeredCount < 0 ? 0 : attempt.answeredCount;
    }
  }
  return DailyStreakSnapshot(
    streakDays: streakDaysEndingNear(days, now),
    questionsToday: questionsToday,
    testsToday: testsToday,
    dailyGoal: dailyGoal < 1 ? 40 : dailyGoal,
  );
}
