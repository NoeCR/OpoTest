import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestPreferences extends ChangeNotifier {
  static const _keyErrorFormat = 'test_error_format';
  static const _keyDurationMinutes = 'test_duration_minutes';
  static const _keyExamSimulation = 'test_exam_simulation';

  int errorFormat = 100;
  int durationMinutes = 0;
  bool examSimulation = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    errorFormat = prefs.getInt(_keyErrorFormat) ?? 100;
    durationMinutes = prefs.getInt(_keyDurationMinutes) ?? 0;
    examSimulation = prefs.getBool(_keyExamSimulation) ?? false;
    notifyListeners();
  }

  Future<void> setErrorFormat(int value) async {
    errorFormat = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyErrorFormat, value);
  }

  Future<void> setDurationMinutes(int value) async {
    durationMinutes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDurationMinutes, value);
  }

  Future<void> setExamSimulation(bool value) async {
    examSimulation = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExamSimulation, value);
  }
}
