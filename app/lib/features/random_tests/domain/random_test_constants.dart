import '../../../models/official_paper.dart';

abstract final class RandomTestConstants {
  static const mixedQuestionCount = 15;
  static const refreshMinDays = 7;
  static const reinforcementMaxAttempts = 50;
  static const reinforcementQuestionCap = 25;

  static const simulacrumIdPrefix = 'simulacrum_random';
  static const simulacrumDefaultQuestions = 100;
  static const simulacrumDefaultMinutes = 90;
  static const simulacrumQuestionOptions = [50, 100, 150];
  static const simulacrumMinuteOptions = [60, 90, 120];
  /// Penalización de los tests oficiales (cada fallo resta 1 acierto).
  static const simulacrumErrorFormat = 100;
  static const simulacrumOfficialTypes = [OfficialPaper.type];

  static bool isSyntheticAttemptTestId(String testId) {
    return testId.startsWith('mixed_random') ||
        testId.startsWith('reinforcement_random') ||
        testId.startsWith('review_random') ||
        testId.startsWith(simulacrumIdPrefix);
  }
}
