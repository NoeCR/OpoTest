import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/custom_tests/application/custom_test_service.dart';
import 'package:opotest/features/custom_tests/data/custom_test_repository_impl.dart';
import 'package:opotest/features/custom_tests/domain/custom_law.dart';
import 'package:opotest/features/custom_tests/domain/custom_question_draft.dart';
import 'package:opotest/features/custom_tests/domain/custom_test_draft.dart';

import 'helpers/database_helper.dart';

void main() {
  group('CustomTestService', () {
    late AppDatabase db;
    late CustomTestService service;

    setUp(() async {
      db = await setUpTestDatabase();
      service = CustomTestService(CustomTestRepositoryImpl(db));
      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'CE', 'name_es': 'Constitución', 'order': '1'},
        ],
        'qByLawNew': {'10': {}},
      });
    });

    tearDown(tearDownTestDatabase);

    test('guardar, listar y recuperar borrador', () async {
      final id = await service.save(
        CustomTestDraft(
          lawId: '10',
          lawCode: 'CE',
          lawName: 'Constitución',
          name: 'Test propio 1',
          questions: [
            CustomQuestionDraft(
              text: 'Pregunta',
              answers: ['A', 'B', 'C', 'D'],
              solution: 1,
            ),
          ],
        ),
      );

      expect(id.startsWith('custom_'), isTrue);

      final summaries = await service.listSummaries(lawId: '10');
      expect(summaries, hasLength(1));
      expect(summaries.first.name, 'Test propio 1');
      expect(summaries.first.questionCount, 1);

      final draft = await service.getDraft(id);
      expect(draft?.name, 'Test propio 1');
      expect(draft?.questions.first.text, 'Pregunta');
    });

    test('actualizar test existente conserva el id', () async {
      final id = await service.save(
        CustomTestDraft(
          lawId: '10',
          lawCode: 'CE',
          lawName: 'Constitución',
          name: 'Original',
          questions: [
            CustomQuestionDraft(
              text: 'P1',
              answers: ['A', 'B', 'C', 'D'],
              solution: 1,
            ),
          ],
        ),
      );

      final updatedId = await service.save(
        CustomTestDraft(
          id: id,
          lawId: '10',
          lawCode: 'CE',
          lawName: 'Constitución',
          name: 'Actualizado',
          questions: [
            CustomQuestionDraft(
              text: 'P1',
              answers: ['A', 'B', 'C', 'D'],
              solution: 1,
            ),
            CustomQuestionDraft(
              text: 'P2',
              answers: ['A', 'B', 'C', 'D'],
              solution: 2,
            ),
          ],
        ),
      );

      expect(updatedId, id);
      final draft = await service.getDraft(id);
      expect(draft?.name, 'Actualizado');
      expect(draft?.questions, hasLength(2));
    });

    test('guardar con Otros crea sección custom en legislación', () async {
      final id = await service.save(
        CustomTestDraft(
          lawId: customLawOthersOption,
          customLawName: 'Psicotécnicos',
          name: 'Test sección nueva',
          questions: [
            CustomQuestionDraft(
              text: 'P',
              answers: ['A', 'B', 'C', 'D'],
              solution: 1,
            ),
          ],
        ),
      );

      expect(id.startsWith('custom_'), isTrue);
      final laws = await db.getLaws();
      final customLaw = laws.firstWhere((l) => isCustomLawId(l['id'] as String));
      expect(customLaw['name'], 'Psicotécnicos');

      final grouped = await db.allContentIdsGroupedByLaw();
      expect(grouped[customLaw['id'] as String], contains(id));
    });

    test('eliminar test y excluir de getAllTestIds', () async {
      await db.upsertOfficialTest(sampleTestJson(id: 'official_1'));
      final customId = await service.save(
        CustomTestDraft(
          lawId: '10',
          lawCode: 'CE',
          lawName: 'Constitución',
          name: 'Custom',
          questions: [
            CustomQuestionDraft(
              text: 'P',
              answers: ['A', 'B', 'C', 'D'],
              solution: 1,
            ),
          ],
        ),
      );

      final allBefore = await db.getAllTestIds();
      expect(allBefore, contains('official_1'));
      expect(allBefore, isNot(contains(customId)));

      expect(await db.getAllCustomTestIds(), [customId]);

      final ownIds = await db.testIdsForLawSource('10', AppDatabase.testSourceCustom);
      expect(ownIds, contains(customId));

      await service.delete(customId);
      expect(await service.listSummaries(), isEmpty);
      expect(await db.getAllTestIds(), ['official_1']);
      expect(await db.getAllCustomTestIds(), isEmpty);
    });
  });
}
