import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/models/content_kind.dart';
import 'package:opotest/models/test_options.dart';

void main() {
  group('ContentKind', () {
    test('labels en español', () {
      expect(ContentKind.tests.label, 'Tests');
      expect(ContentKind.exams.label, 'Exámenes');
      expect(ContentKind.official.label, 'Preguntas oficiales');
      expect(ContentKind.officialPaper.label, 'Pruebas reales');
      expect(ContentKind.own.label, 'Preguntas propias');
    });

    test('dbType coincide con tipos de BD', () {
      expect(ContentKind.tests.dbType, 'test');
      expect(ContentKind.exams.dbType, 'exam');
      expect(ContentKind.official.dbType, 'realexam');
      expect(ContentKind.officialPaper.dbType, 'officialpaper');
      expect(ContentKind.own.dbType, 'own');
    });

    test('lawTabs no incluye pruebas reales', () {
      expect(ContentKindX.lawTabs, isNot(contains(ContentKind.officialPaper)));
      expect(ContentKindX.lawTabs, containsAll([
        ContentKind.tests,
        ContentKind.exams,
        ContentKind.official,
        ContentKind.own,
      ]));
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
