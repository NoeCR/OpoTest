import 'package:shared_preferences/shared_preferences.dart';

class FailedQuestionsExportStore {
  static String _key(String userId) => 'failed_questions_last_export_$userId';

  Future<DateTime?> lastExportAt(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastExportAt(String userId, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), at.toIso8601String());
  }
}
