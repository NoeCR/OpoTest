class Question {
  final int order;
  final String text;
  final List<String> answers;
  final int solution;
  final String clarificationHtml;

  const Question({
    required this.order,
    required this.text,
    required this.answers,
    required this.solution,
    required this.clarificationHtml,
  });

  factory Question.fromApiMap(Map<String, dynamic> item) {
    final q = item['q'] as Map<String, dynamic>? ?? {};
    return Question(
      order: int.tryParse(item['order']?.toString() ?? '') ?? 0,
      text: q['text_es']?.toString() ?? '',
      answers: [
        q['answer1_es']?.toString() ?? '',
        q['answer2_es']?.toString() ?? '',
        q['answer3_es']?.toString() ?? '',
        q['answer4_es']?.toString() ?? '',
      ],
      solution: int.tryParse(q['solution']?.toString() ?? '') ?? 0,
      clarificationHtml: q['textClarification_es']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toApiMap() => {
        'order': '$order',
        'q': {
          'text_es': text,
          'answer1_es': answers.isNotEmpty ? answers[0] : '',
          'answer2_es': answers.length > 1 ? answers[1] : '',
          'answer3_es': answers.length > 2 ? answers[2] : '',
          'answer4_es': answers.length > 3 ? answers[3] : '',
          'solution': '$solution',
          'textClarification_es': clarificationHtml,
        },
      };
}

class TestDefinition {
  final String id;
  final String name;
  final String type;
  final List<Question> questions;

  const TestDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.questions,
  });

  factory TestDefinition.fromApiJson(Map<String, dynamic> json) {
    final test = json['test'] as Map<String, dynamic>? ?? {};
    final rawQ = test['q'];
    List<dynamic> list = [];
    if (rawQ is Map) {
      list = rawQ['1'] as List? ?? rawQ[1] as List? ?? [];
    } else if (rawQ is List && rawQ.length > 1) {
      list = rawQ[1] as List? ?? [];
    }
    return TestDefinition(
      id: test['id']?.toString() ?? '',
      name: test['name']?.toString() ?? 'Test',
      type: test['type']?.toString() ?? 'test',
      questions: list.map((e) => Question.fromApiMap(e as Map<String, dynamic>)).toList(),
    );
  }

  /// JSON compatible con [fromApiJson], para persistir tests sintéticos o oficiales.
  Map<String, dynamic> toApiJson() => {
        'error': 0,
        'test': {
          'id': id,
          'name': name,
          'type': type,
          'q': {
            '1': questions.map((q) => q.toApiMap()).toList(),
          },
        },
      };
}
