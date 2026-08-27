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
