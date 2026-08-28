import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestPreferences extends ChangeNotifier {
  static const _keyErrorFormat = 'test_error_format';
  static const _keyDurationMinutes = 'test_duration_minutes';
  static const _keyExamSimulation = 'test_exam_simulation';
  static const _keySimulacrumQuestions = 'simulacrum_questions';
  static const _keySimulacrumMinutes = 'simulacrum_minutes';
  static const _keySimulacrumExcluded = 'simulacrum_excluded_test_ids';

  int errorFormat = 100;
  int durationMinutes = 0;
  bool examSimulation = false;
  int simulacrumQuestions = 100;
  int simulacrumMinutes = 90;
  Set<String> simulacrumExcludedTestIds = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    errorFormat = prefs.getInt(_keyErrorFormat) ?? 100;
    durationMinutes = prefs.getInt(_keyDurationMinutes) ?? 0;
    examSimulation = prefs.getBool(_keyExamSimulation) ?? false;
    simulacrumQuestions = prefs.getInt(_keySimulacrumQuestions) ?? 100;
    simulacrumMinutes = prefs.getInt(_keySimulacrumMinutes) ?? 90;
    simulacrumExcludedTestIds = {...prefs.getStringList(_keySimulacrumExcluded) ?? const <String>[]};
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

  Future<void> setSimulacrumQuestions(int value) async {
    simulacrumQuestions = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySimulacrumQuestions, value);
  }

  Future<void> setSimulacrumMinutes(int value) async {
    simulacrumMinutes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySimulacrumMinutes, value);
  }

  bool isSimulacrumPaperIncluded(String testId) => !simulacrumExcludedTestIds.contains(testId);

  Future<void> setSimulacrumPaperIncluded(String testId, bool included) async {
    if (included) {
      simulacrumExcludedTestIds.remove(testId);
    } else {
      simulacrumExcludedTestIds.add(testId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySimulacrumExcluded, simulacrumExcludedTestIds.toList());
  }

  Future<void> includeAllSimulacrumPapers() async {
    simulacrumExcludedTestIds = {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySimulacrumExcluded, const []);
  }

  Future<void> includeSimulacrumPapers(Iterable<String> testIds) async {
    final ids = testIds.toSet();
    simulacrumExcludedTestIds = {
      for (final id in simulacrumExcludedTestIds)
        if (!ids.contains(id)) id,
    };
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySimulacrumExcluded, simulacrumExcludedTestIds.toList());
  }

  Future<void> excludeSimulacrumPapers(Iterable<String> testIds) async {
    simulacrumExcludedTestIds = {...simulacrumExcludedTestIds, ...testIds};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySimulacrumExcluded, simulacrumExcludedTestIds.toList());
  }
}
