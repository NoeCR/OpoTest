import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/database/app_database.dart';
import 'package:testea_local/features/backup/application/content_backup_service.dart';
import 'package:testea_local/features/backup/data/content_backup_repository_impl.dart';
import 'package:testea_local/features/backup/domain/backup_constants.dart';
import 'package:testea_local/features/custom_tests/domain/custom_question_draft.dart';
import 'package:testea_local/features/custom_tests/domain/custom_test_draft.dart';
import 'package:testea_local/features/custom_tests/data/custom_test_payload_builder.dart';

import 'helpers/database_helper.dart';

void main() {
  group('ContentBackupService', () {
    late AppDatabase db;
    late ContentBackupService service;
    late Directory tempDir;

    setUp(() async {
      db = await setUpTestDatabase();
      service = ContentBackupService(ContentBackupRepositoryImpl(db));
      tempDir = await Directory.systemTemp.createTemp('opotest_content_backup_');

      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'CE', 'name_es': 'Constitución', 'order': '1'},
        ],
        'qByLawNew': {'10': {}},
      });
      await db.upsertOfficialTest(sampleTestJson(id: '1001', lawId: '10'));
    });

    tearDown(() async {
      await tearDownTestDatabase();
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('export e import restauran tests oficiales y custom', () async {
      const builder = CustomTestPayloadBuilder();
      await db.upsertCustomTest(
        builder.build(
          testId: 'custom_1',
          draft: const CustomTestDraft(
            lawId: '10',
            lawCode: 'CE',
            lawName: 'Constitución',
            name: 'Propio',
            questions: [
              CustomQuestionDraft(
                text: 'P',
                answers: ['A', 'B', 'C', 'D'],
                solution: 1,
              ),
            ],
          ),
        ),
      );

      final exported = await service.export(targetDir: tempDir);
      expect(exported.stats['tests_official'], 1);
      expect(exported.stats['tests_custom'], 1);

      await db.deleteCustomTest('custom_1');
      await AppDatabase.db.delete('tests', where: 'id = ?', whereArgs: ['1001']);
      expect(await db.countTests(), 0);

      final payload = jsonDecode(await File(exported.filePath).readAsString()) as Map<String, dynamic>;
      expect(payload['kind'], contentBackupKind);

      final imported = await ContentBackupRepositoryImpl(db).importPayload(payload);
      expect(imported.testsOfficial, 1);
      expect(imported.testsCustom, 1);
      expect(await db.countTests(), 2);
    });
  });
}
