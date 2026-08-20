class CustomQuestionDraft {
  const CustomQuestionDraft({
    this.text = '',
    this.answers = const ['', '', '', ''],
    this.solution = 1,
    this.clarificationHtml = '',
  });

  final String text;
  final List<String> answers;
  final int solution;
  final String clarificationHtml;

  CustomQuestionDraft copyWith({
    String? text,
    List<String>? answers,
    int? solution,
    String? clarificationHtml,
  }) {
    return CustomQuestionDraft(
      text: text ?? this.text,
      answers: answers ?? List<String>.from(this.answers),
      solution: solution ?? this.solution,
      clarificationHtml: clarificationHtml ?? this.clarificationHtml,
    );
  }

  static CustomQuestionDraft empty() => const CustomQuestionDraft();
}
