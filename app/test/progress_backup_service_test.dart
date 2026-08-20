import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/database/app_database.dart';
import 'package:testea_local/features/backup/application/progress_backup_service.dart';
import 'package:testea_local/features/backup/data/progress_backup_repository_impl.dart';
import 'package:testea_local/features/backup/domain/backup_constants.dart';
import 'package:testea_local/features/backup/domain/backup_validation.dart';
import 'package:testea_local/models/local_user.dart';

import 'helpers/database_helper.dart';

void main() {
  group('ProgressBackupService', () {
    late AppDatabase db;
    late ProgressBackupService service;
    late LocalUser user;

    setUp(() async {
      db = await setUpTestDatabase();
      service = ProgressBackupService(ProgressBackupRepositoryImpl(db));
      user = LocalUser(
        id: 'user-1',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
      await db.upsertOfficialTest(sampleTestJson(id: '1001'));
      await db.saveAttempt(TestAttempt(
        id: 'att-1',
        userId: user.id,
        testId: '1001',
        testName: 'Test demo',
        finishedAt: DateTime.parse('2026-08-01T10:00:00'),
        durationSeconds: 120,
        netScore: 8,
        percentScore: 80,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 100,
      ));
    });

    tearDown(tearDownTestDatabase);

    test('exportAll genera payload v2', () async {
      final tempDir = await Directory.systemTemp.createTemp('opotest_progress_backup_');
      final result = await service.exportAll(targetDir: tempDir);
      final payload = await ProgressBackupRepositoryImpl(db).buildExportPayload();
      expect(payload['kind'], progressBackupKind);
      expect(payload['version'], progressBackupVersion);
      expect(result.stats['total_attempts'], 1);
      await tempDir.delete(recursive: true);
    });

    test('import fusiona intentos sin borrar previos', () async {
      final payload = await ProgressBackupRepositoryImpl(db).buildExportPayload();
      validateProgressBackup(payload);

      await AppDatabase.db.delete('attempts');
      expect(await db.attemptsForUser(user.id), isEmpty);

      final imported = await ProgressBackupRepositoryImpl(db).importPayload(
        normalizeProgressBackup(payload),
      );
      expect(imported.attempts, 1);
      expect(await db.attemptsForUser(user.id), hasLength(1));
    });
  });
}
