import 'question_review_state.dart';

/// Leitner de 5 cajas con intervalos fijos: 1 / 3 / 7 / 16 / 30 días.
abstract final class SpacedReviewScheduler {
  static const boxCount = 5;
  static const intervalDays = [1, 3, 7, 16, 30];

  static DateTime calendarDay(DateTime at) => DateTime(at.year, at.month, at.day);

  static DateTime dueAfterBox(int box, DateTime now) {
    final clamped = box.clamp(1, boxCount);
    return calendarDay(now).add(Duration(days: intervalDays[clamped - 1]));
  }

  static QuestionReviewState afterFail({
    required String userId,
    required String testId,
    required int questionIndex,
    required DateTime now,
  }) {
    return QuestionReviewState(
      userId: userId,
      testId: testId,
      questionIndex: questionIndex,
      box: 1,
      nextDue: dueAfterBox(1, now),
      lastResultCorrect: false,
    );
  }

  static QuestionReviewState afterSuccess(QuestionReviewState current, DateTime now) {
    final box = current.box >= boxCount ? boxCount : current.box + 1;
    return QuestionReviewState(
      userId: current.userId,
      testId: current.testId,
      questionIndex: current.questionIndex,
      box: box,
      nextDue: dueAfterBox(box, now),
      lastResultCorrect: true,
    );
  }

  static bool isDue(QuestionReviewState state, DateTime now) {
    return !calendarDay(state.nextDue).isAfter(calendarDay(now));
  }
}
