import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/models/content_kind.dart';
import 'package:testea_local/models/test_options.dart';

void main() {
  group('ContentKind', () {
    test('labels en español', () {
      expect(ContentKind.tests.label, 'Tests');
      expect(ContentKind.exams.label, 'Exámenes');
      expect(ContentKind.official.label, 'Preguntas oficiales');
      expect(ContentKind.own.label, 'Preguntas propias');
    });

    test('dbType coincide con tipos de BD', () {
      expect(ContentKind.tests.dbType, 'test');
      expect(ContentKind.exams.dbType, 'exam');
      expect(ContentKind.official.dbType, 'realexam');
      expect(ContentKind.own.dbType, 'own');
    });
  });

  group('TestOptions', () {
    test('durationLabel formatea minutos', () {
      expect(TestOptions.durationLabel(0), 'Sin límite');
      expect(TestOptions.durationLabel(15), '15 min');
    });

    test('errorFormats incluye penalizaciones estándar', () {
      expect(TestOptions.errorFormats.keys, containsAll([0, 25, 33, 50, 100]));
    });
  });
}
