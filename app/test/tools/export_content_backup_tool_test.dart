import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/backup/data/content_backup_repository_impl.dart';
import 'package:opotest/features/backup/domain/backup_validation.dart';
import 'package:opotest/services/content_importer.dart';

/// Ejecutar con:
///   flutter test test/tools/export_content_backup_tool_test.dart
///
/// Variables de entorno opcionales:
///   OPOTEST_DATA_PATH  — carpeta data (default: ../data desde app/)
///   OPOTEST_OUTPUT     — ruta del JSON de salida
void main() {
  test('generates content backup json for distribution', () async {
    final appDir = Directory.current.path;
    final repoRoot = p.normalize(p.join(appDir, '..'));
    final dataPath = Platform.environment['OPOTEST_DATA_PATH'] ?? p.join(repoRoot, 'data');
    final outputPath = Platform.environment['OPOTEST_OUTPUT'] ??
        p.join(repoRoot, 'releases', 'OpoTest-content.json');

    final manifest = File(p.join(dataPath, 'manifest.json'));
    expect(manifest.existsSync(), isTrue, reason: 'Ejecuta node scripts/export-temario.cjs');

    await AppDatabase.initForTest();
    addTearDown(AppDatabase.disposeForTest);

    final db = AppDatabase();
    final result = await ContentImporter(db).importFromDirectory(dataPath);
    expect(result.tests, greaterThan(0), reason: 'Sin tests en $dataPath');

    final payload = await ContentBackupRepositoryImpl(db).buildExportPayload();
    validateContentBackup(payload);

    final outFile = File(outputPath);
    outFile.parent.createSync(recursive: true);
    await outFile.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

    final stats = payload['stats'] as Map;
    // ignore: avoid_print
    print('OK ${outFile.path} · ${stats['laws']} leyes · ${stats['tests_official']} tests');
  });
}
