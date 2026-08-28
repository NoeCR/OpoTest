import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/temario_search/application/temario_search_service.dart';
import 'package:opotest/features/temario_search/domain/temario_search.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('TemarioSearchService', () {
    late AppDatabase db;
    late TemarioSearchService service;

    setUp(() async {
      db = await setUpTestDatabase();
      service = TemarioSearchService(db);
      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'CE', 'name_es': 'Constitución Española', 'order': '1'},
          {'id': '11', 'code': 'EBEP', 'name_es': 'Estatuto Básico', 'order': '2'},
        ],
        'qByLawNew': {'10': {}, '11': {}},
      });
      await db.importTitle('10', {
        'title': {'id': '82', 'code': 'T1', 'name_es': 'Derechos fundamentales', 'order': '1'},
      });
      await db.importTitle('11', {
        'title': {'id': '90', 'code': 'T4', 'name_es': 'Excedencia y situaciones', 'order': '1'},
      });
      await db.upsertOfficialTest(
        sampleTestJson(id: '1001', name: 'Test Constitución T1', lawId: '10', titleId: '82'),
      );
      await db.upsertOfficialTest(
        sampleTestJson(id: '1002', name: 'Silencio administrativo', lawId: '11', titleId: '90'),
      );
      final withQuestion = sampleTestJson(
        id: '1003',
        name: 'Test EBEP situaciones',
        lawId: '11',
        titleId: '90',
      );
      final questions = (withQuestion['test'] as Map)['q'] as Map;
      final list = questions['1'] as List;
      (list[0] as Map)['q']['text_es'] = 'La excedencia voluntaria requiere un año de servicios.';
      await db.upsertOfficialTest(withQuestion);
    });

    tearDown(tearDownTestDatabase);

    test('consulta corta no busca', () async {
      expect((await service.search('c')).isEmpty, isTrue);
      expect((await service.search('  ')).isEmpty, isTrue);
    });

    test('encuentra ley por código exacto y nombre sin acentos', () async {
      final byCode = await service.search('CE');
      expect(byCode.laws.single.id, '10');
      expect(byCode.laws.single.rank, SearchMatchRank.exact);

      final byName = await service.search('constitucion');
      expect(byName.laws.any((h) => h.id == '10'), isTrue);
    });

    test('encuentra título por nombre', () async {
      final results = await service.search('excedencia');
      expect(results.titles.single.id, '90');
      expect(results.titles.single.rank, SearchMatchRank.prefix);
    });

    test('ranking de tests: exacto antes que contiene', () async {
      final results = await service.search('silencio administrativo');
      expect(results.tests.first.id, '1002');
      expect(results.tests.first.rank, SearchMatchRank.exact);
    });

    test('encuentra pregunta por enunciado y no congela con límite', () async {
      final results = await service.search('excedencia voluntaria');
      expect(results.questions, isNotEmpty);
      expect(results.questions.first.testId, '1003');
      expect(results.questions.length, lessThanOrEqualTo(temarioSearchQuestionLimit));
    });

    test('sin coincidencias devuelve grupos vacíos', () async {
      final results = await service.search('xyzzy');
      expect(results.isEmpty, isTrue);
    });
  });
}
