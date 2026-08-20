import 'package:shared_preferences/shared_preferences.dart';
import 'package:testea_local/database/app_database.dart';

Future<AppDatabase> setUpTestDatabase() async {
  SharedPreferences.setMockInitialValues({});
  await AppDatabase.initForTest();
  return AppDatabase();
}

Future<void> tearDownTestDatabase() async {
  await AppDatabase.disposeForTest();
}

Map<String, dynamic> sampleTestJson({
  String id = '1001',
  String name = 'Test demo',
  String lawId = '10',
  String titleId = '82',
  String type = 'test',
  int questionCount = 4,
}) {
  final questions = List.generate(questionCount, (i) {
    return {
      'order': '${i + 1}',
      'q': {
        'text_es': 'Pregunta ${i + 1}',
        'answer1_es': 'A',
        'answer2_es': 'B',
        'answer3_es': 'C',
        'answer4_es': 'D',
        'solution': '${(i % 4) + 1}',
        'textClarification_es': '',
      },
    };
  });

  return {
    'test': {
      'id': id,
      'name': name,
      'type': type,
      'idLaw': lawId,
      'idTitle': titleId,
      'idChapter': '',
      'idSection': '',
      'idArticle': '',
      'index': '1',
      'q': {
        '1': questions,
      },
    },
  };
}
