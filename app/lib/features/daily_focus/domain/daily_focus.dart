import '../../random_tests/domain/random_test_mode.dart';

/// Marcas más antiguas que esto no entran en el foco del día.
const markedFocusMaxAge = Duration(days: 30);

enum DailyFocusKind {
  markedReview,
  reinforcement,
  weakTest,
  retryLast,
  classic,
  getStarted,
}

class WeakTestHint {
  const WeakTestHint({
    required this.testId,
    required this.testName,
    required this.lastPercent,
    required this.attempts,
  });

  final String testId;
  final String testName;
  final double lastPercent;
  final int attempts;
}

class LastAttemptHint {
  const LastAttemptHint({
    required this.testId,
    required this.testName,
  });

  final String testId;
  final String testName;
}

class DailyFocusSnapshot {
  const DailyFocusSnapshot({
    required this.contentReady,
    this.recentMarkedCount = 0,
    this.recentFailCount = 0,
    this.weakest,
    this.lastAttempt,
  });

  final bool contentReady;
  final int recentMarkedCount;
  final int recentFailCount;
  final WeakTestHint? weakest;
  final LastAttemptHint? lastAttempt;
}

class DailyFocusAction {
  const DailyFocusAction({
    required this.kind,
    required this.title,
    required this.reason,
    this.randomMode,
    this.testId,
  });

  final DailyFocusKind kind;
  final String title;
  final String reason;
  final RandomTestMode? randomMode;
  final String? testId;
}

class DailyFocusPlan {
  const DailyFocusPlan({
    required this.primary,
    this.secondary = const [],
  });

  final DailyFocusAction primary;
  final List<DailyFocusAction> secondary;

  List<DailyFocusAction> get actions => [primary, ...secondary];
}

bool isRecentMark(DateTime markedAt, DateTime now) {
  final age = now.difference(markedAt);
  if (age.isNegative) return true;
  return age <= markedFocusMaxAge;
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Marca que aún pide foco hoy: reciente y no cubierta por un test de repaso de hoy.
bool countsForMarkedFocus({
  required DateTime markedAt,
  required DateTime now,
  DateTime? lastMarkedReviewAt,
}) {
  if (!isRecentMark(markedAt, now)) return false;
  if (lastMarkedReviewAt == null) return true;
  if (!isSameCalendarDay(lastMarkedReviewAt, now)) return true;
  return markedAt.isAfter(lastMarkedReviewAt);
}

/// Elige el test con peor último % (menor que 100). Empate: más intentos.
WeakTestHint? pickWeakestTest(Iterable<WeakTestHint> candidates) {
  final weak = candidates.where((c) => c.lastPercent < 100).toList();
  if (weak.isEmpty) return null;
  weak.sort((a, b) {
    final byPercent = a.lastPercent.compareTo(b.lastPercent);
    if (byPercent != 0) return byPercent;
    return b.attempts.compareTo(a.attempts);
  });
  return weak.first;
}

/// Orden fijo: marcas pendientes de hoy → fallos 7 días → test más flojo → último intento → azar.
DailyFocusPlan buildDailyFocus(DailyFocusSnapshot snapshot) {
  final candidates = <DailyFocusAction>[];

  if (snapshot.recentMarkedCount > 0) {
    final n = snapshot.recentMarkedCount;
    candidates.add(
      DailyFocusAction(
        kind: DailyFocusKind.markedReview,
        title: 'Repasar marcas',
        reason: n == 1
            ? 'Tienes 1 pregunta marcada para revisión'
            : 'Tienes $n preguntas marcadas para revisión',
        randomMode: RandomTestMode.markedReview,
      ),
    );
  }

  if (snapshot.recentFailCount > 0) {
    final n = snapshot.recentFailCount;
    candidates.add(
      DailyFocusAction(
        kind: DailyFocusKind.reinforcement,
        title: 'Repasar fallos',
        reason: n == 1
            ? 'Tienes 1 fallo de los últimos 7 días'
            : 'Tienes $n fallos de los últimos 7 días',
        randomMode: RandomTestMode.reinforcement,
      ),
    );
  }

  final weakest = snapshot.weakest;
  if (weakest != null) {
    candidates.add(
      DailyFocusAction(
        kind: DailyFocusKind.weakTest,
        title: weakest.testName,
        reason: 'Último intento al ${weakest.lastPercent.round()}%',
        testId: weakest.testId,
      ),
    );
  }

  if (candidates.isEmpty && snapshot.lastAttempt != null) {
    final last = snapshot.lastAttempt!;
    candidates.add(
      DailyFocusAction(
        kind: DailyFocusKind.retryLast,
        title: 'Reintentar último',
        reason: last.testName,
        testId: last.testId,
      ),
    );
  }

  if (candidates.isEmpty && snapshot.contentReady) {
    candidates.add(
      const DailyFocusAction(
        kind: DailyFocusKind.classic,
        title: 'Test al azar',
        reason: 'Haz un test de cualquier ley para empezar',
        randomMode: RandomTestMode.classic,
      ),
    );
  }

  if (candidates.isEmpty) {
    return const DailyFocusPlan(
      primary: DailyFocusAction(
        kind: DailyFocusKind.getStarted,
        title: 'Importa el temario',
        reason: 'Haz un test de cualquier ley para empezar',
      ),
    );
  }

  return DailyFocusPlan(
    primary: candidates.first,
    secondary: candidates.skip(1).take(2).toList(),
  );
}
