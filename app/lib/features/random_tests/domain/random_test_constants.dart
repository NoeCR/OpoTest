abstract final class RandomTestConstants {
  static const mixedQuestionCount = 15;
  static const refreshMinDays = 7;
  static const reinforcementMaxAttempts = 50;
  static const reinforcementQuestionCap = 25;

  static bool isSyntheticAttemptTestId(String testId) {
    return testId.startsWith('mixed_random') ||
        testId.startsWith('reinforcement_random') ||
        testId.startsWith('review_random');
  }
}
