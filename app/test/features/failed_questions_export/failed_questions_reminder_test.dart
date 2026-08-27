import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/failed_questions_export/domain/failed_questions_range.dart';
import 'package:opotest/features/failed_questions_export/domain/failed_questions_reminder.dart';

void main() {
  group('shouldPromptFailedQuestionsReminder', () {
    final now = DateTime(2026, 8, 27, 10, 0);

    test('desactivado no avisa', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.none,
          now: now,
        ),
        isFalse,
      );
    });

    test('diario avisa si no hay exportación ni aviso previos', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.daily,
          now: now,
        ),
        isTrue,
      );
    });

    test('diario no avisa el mismo día del último aviso', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.daily,
          now: now,
          lastPromptedAt: DateTime(2026, 8, 27, 8, 0),
        ),
        isFalse,
      );
    });

    test('diario avisa al día siguiente del último aviso', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.daily,
          now: now,
          lastPromptedAt: DateTime(2026, 8, 26, 22, 0),
        ),
        isTrue,
      );
    });

    test('diario no avisa si se exportó hoy', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.daily,
          now: now,
          lastExportAt: DateTime(2026, 8, 27, 9, 0),
          lastPromptedAt: DateTime(2026, 8, 26, 9, 0),
        ),
        isFalse,
      );
    });

    test('semanal avisa a los 7 días', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.weekly,
          now: now,
          lastExportAt: DateTime(2026, 8, 20, 10, 0),
        ),
        isTrue,
      );
    });

    test('semanal no avisa a los 6 días', () {
      expect(
        shouldPromptFailedQuestionsReminder(
          interval: FailedQuestionsReminderInterval.weekly,
          now: now,
          lastExportAt: DateTime(2026, 8, 21, 10, 0),
        ),
        isFalse,
      );
    });
  });

  test('etiquetas y preset de exportación', () {
    expect(FailedQuestionsReminderInterval.none.label, 'Ninguno');
    expect(FailedQuestionsReminderInterval.daily.label, 'Diario');
    expect(FailedQuestionsReminderInterval.weekly.label, 'Semanal');
    expect(FailedQuestionsReminderInterval.daily.exportPreset, FailedQuestionsPreset.lastDay);
    expect(FailedQuestionsReminderInterval.weekly.exportPreset, FailedQuestionsPreset.last7Days);
    expect(failedQuestionsReminderIntervalFromStorage(null), FailedQuestionsReminderInterval.none);
    expect(
      failedQuestionsReminderIntervalFromStorage('weekly'),
      FailedQuestionsReminderInterval.weekly,
    );
    expect(
      failedQuestionsReminderIntervalFromStorage('debugMinute'),
      FailedQuestionsReminderInterval.none,
    );
  });
}
