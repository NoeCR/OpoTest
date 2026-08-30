import 'failed_questions_range.dart';

enum FailedQuestionsReminderInterval {
  none,
  daily,
  weekly,
}

extension FailedQuestionsReminderIntervalX on FailedQuestionsReminderInterval {
  String get label => switch (this) {
        FailedQuestionsReminderInterval.none => 'Ninguno',
        FailedQuestionsReminderInterval.daily => 'Diario',
        FailedQuestionsReminderInterval.weekly => 'Semanal',
      };

  String get storageKey => name;

  FailedQuestionsPreset get exportPreset => switch (this) {
        FailedQuestionsReminderInterval.none => FailedQuestionsPreset.lastDay,
        FailedQuestionsReminderInterval.daily => FailedQuestionsPreset.lastDay,
        FailedQuestionsReminderInterval.weekly => FailedQuestionsPreset.last7Days,
      };
}

FailedQuestionsReminderInterval failedQuestionsReminderIntervalFromStorage(String? value) {
  return FailedQuestionsReminderInterval.values.firstWhere(
    (interval) => interval.name == value,
    orElse: () => FailedQuestionsReminderInterval.none,
  );
}

String failedQuestionsReminderBody({
  required FailedQuestionsReminderInterval interval,
  required int failCount,
  int dueCount = 0,
}) {
  final periodLabel = interval == FailedQuestionsReminderInterval.weekly
      ? 'esta semana'
      : 'el último día';
  final fails = failCount == 1
      ? 'Tienes 1 pregunta fallada de $periodLabel.'
      : 'Tienes $failCount preguntas falladas de $periodLabel.';
  if (dueCount <= 0) return '$fails ¿Quieres generar el informe para ${failCount == 1 ? 'estudiarla' : 'estudiarlas'}?';
  final due = dueCount == 1
      ? 'Tienes 1 pregunta para repasar hoy.'
      : 'Tienes $dueCount para repasar hoy.';
  return '$fails $due ¿Quieres generar el informe?';
}

/// Decide si hay que avisar al abrir la app, según la última exportación o el último aviso.
bool shouldPromptFailedQuestionsReminder({
  required FailedQuestionsReminderInterval interval,
  required DateTime now,
  DateTime? lastExportAt,
  DateTime? lastPromptedAt,
}) {
  if (interval == FailedQuestionsReminderInterval.none) return false;
  final last = _latest(lastExportAt, lastPromptedAt);
  if (last == null) return true;

  final lastDay = DateTime(last.year, last.month, last.day);
  final today = DateTime(now.year, now.month, now.day);
  return switch (interval) {
    FailedQuestionsReminderInterval.none => false,
    FailedQuestionsReminderInterval.daily => today.isAfter(lastDay),
    FailedQuestionsReminderInterval.weekly => today.difference(lastDay).inDays >= 7,
  };
}

DateTime? _latest(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
