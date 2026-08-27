import 'package:shared_preferences/shared_preferences.dart';

import '../domain/failed_questions_reminder.dart';

class FailedQuestionsExportStore {
  static const intervalKey = 'failed_questions_reminder_interval';

  static String _exportKey(String userId) => 'failed_questions_last_export_$userId';

  static String _promptKey(String userId) => 'failed_questions_last_prompt_$userId';

  Future<DateTime?> lastExportAt(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return _parseDate(prefs.getString(_exportKey(userId)));
  }

  Future<void> setLastExportAt(String userId, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportKey(userId), at.toIso8601String());
  }

  Future<FailedQuestionsReminderInterval> reminderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return failedQuestionsReminderIntervalFromStorage(prefs.getString(intervalKey));
  }

  Future<void> setReminderInterval(FailedQuestionsReminderInterval interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(intervalKey, interval.storageKey);
  }

  Future<DateTime?> lastPromptedAt(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return _parseDate(prefs.getString(_promptKey(userId)));
  }

  Future<void> setLastPromptedAt(String userId, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promptKey(userId), at.toIso8601String());
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
