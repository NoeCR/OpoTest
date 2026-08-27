import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opotest/features/failed_questions_export/data/failed_questions_export_store.dart';
import 'package:opotest/features/failed_questions_export/domain/failed_questions_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FailedQuestionsExportStore reminder', () {
    late FailedQuestionsExportStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = FailedQuestionsExportStore();
    });

    test('intervalo por defecto es ninguno', () async {
      expect(await store.reminderInterval(), FailedQuestionsReminderInterval.none);
    });

    test('persiste intervalo y último aviso', () async {
      await store.setReminderInterval(FailedQuestionsReminderInterval.daily);
      expect(await store.reminderInterval(), FailedQuestionsReminderInterval.daily);

      final at = DateTime(2026, 8, 27, 10, 15);
      await store.setLastPromptedAt('user-1', at);
      expect(await store.lastPromptedAt('user-1'), at);
      expect(await store.lastPromptedAt('user-2'), isNull);
    });
  });
}
