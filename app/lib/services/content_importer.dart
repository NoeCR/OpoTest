import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

class ContentImporter {
  ContentImporter(this._db);

  final AppDatabase _db;

  /// Ruta por defecto en desktop: carpeta `data` hermana de `app`.
  static String defaultDataPath() {
    final cwd = Directory.current.path;
    final candidate = p.normalize(p.join(cwd, '..', 'data'));
    if (Directory(candidate).existsSync()) return candidate;
    return p.normalize(p.join(cwd, 'data'));
  }

  /// Busca el temario en rutas válidas según plataforma.
  static Future<String> resolveDataPath() async {
    for (final candidate in await candidatePaths()) {
      if (_isValidDataDir(candidate)) return candidate;
    }
    throw StateError(
      'Temario no encontrado. '
      'En Android/iOS: ejecuta scripts/push-data-android.ps1 (o copia la carpeta data exportada).',
    );
  }

  static Future<List<String>> candidatePaths() async {
    final paths = <String>[];
    final mobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!kIsWeb) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        paths.add(p.join(docs.path, 'data'));
        // Evita carpeta duplicada tras push-data (data/data).
        paths.add(p.join(docs.path, 'data', 'data'));
      } catch (_) {}
      if (Platform.isAndroid) {
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            paths.add(p.join(ext.path, 'data'));
            paths.add(p.join(ext.path, 'data', 'data'));
          }
        } catch (_) {}
      }
    }

    if (!mobile) {
      paths.add(defaultDataPath());
    }
    return paths;
  }

  static bool _isValidDataDir(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return false;
    final lawsIndex = File(p.join(dirPath, 'laws-index.json'));
    if (lawsIndex.existsSync()) {
      try {
        final data = jsonDecode(lawsIndex.readAsStringSync()) as Map<String, dynamic>;
        if ((data['laws'] as List?)?.isNotEmpty ?? false) return true;
      } catch (_) {}
    }
    return File(p.join(dirPath, 'manifest.json')).existsSync() &&
        Directory(p.join(dirPath, 'tests')).existsSync();
  }

  Future<ImportResult> importFromDirectory(String dataPath) async {
    final dir = Directory(dataPath);
    if (!dir.existsSync()) {
      throw StateError('No se encuentra la carpeta de datos: $dataPath');
    }

    var laws = 0;
    var titles = 0;
    var tests = 0;

    final lawsIndexFile = File(p.join(dataPath, 'laws-index.json'));
    if (lawsIndexFile.existsSync()) {
      final lawsIndex = jsonDecode(await lawsIndexFile.readAsString()) as Map<String, dynamic>;
      await _db.importLawIndex(lawsIndex);
      laws = (lawsIndex['laws'] as List?)?.length ?? 0;
    }

    titles = await importTitlesFromDirectory(dataPath);

    tests = await importTestsFromDirectory(dataPath);

    await _finalizeImportMeta(dataPath);
    return ImportResult(laws: laws, titles: titles, tests: tests);
  }

  /// Solo `laws/<id>/titles/<titleId>.json`. Los JSON de artículos anidados
  /// también traen `title` y no deben sobrescribir el payload del título.
  Future<int> importTitlesFromDirectory(String dataPath) async {
    final lawsDir = Directory(p.join(dataPath, 'laws'));
    if (!lawsDir.existsSync()) return 0;

    var titles = 0;
    await for (final lawDir in lawsDir.list()) {
      if (lawDir is! Directory) continue;
      final titlesDir = Directory(p.join(lawDir.path, 'titles'));
      if (!titlesDir.existsSync()) continue;
      await for (final entity in titlesDir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final data = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          if (data.containsKey('title') && data.containsKey('arChapters')) {
            await _db.importTitle(p.basename(lawDir.path), data);
            titles++;
          }
        } catch (e) {
          debugPrint('Testea title skip ${entity.path}: $e');
        }
      }
    }
    debugPrint('Testea import: $titles titles');
    return titles;
  }

  /// Importa solo tests (útil si leyes/títulos ya están en SQLite).
  Future<int> importTestsFromDirectory(String dataPath) async {
    final testsDir = Directory(p.join(dataPath, 'tests'));
    if (!testsDir.existsSync()) return 0;

    var imported = 0;
    var skippedCustom = 0;

    await for (final entity in testsDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final saved = await _db.upsertOfficialTest(json);
        if (saved) {
          imported++;
          if (imported % 120 == 0) {
            debugPrint('Testea import: $imported tests...');
          }
        } else {
          skippedCustom++;
        }
      } catch (e) {
        debugPrint('Testea import skip ${entity.path}: $e');
      }
    }

    debugPrint('Testea import: $imported tests total · $skippedCustom custom preservados');
    return imported;
  }

  Future<int> importTestsOnly(String dataPath) async {
    final tests = await importTestsFromDirectory(dataPath);
    await _finalizeImportMeta(dataPath);
    return tests;
  }

  Future<void> _finalizeImportMeta(String dataPath) async {
    await _db.setSyncMeta('content_path', dataPath);
    await _db.setSyncMeta('last_import', DateTime.now().toIso8601String());
    await _db.setSyncMeta('question_count', '');

    final manifestFile = File(p.join(dataPath, 'manifest.json'));
    if (manifestFile.existsSync()) {
      try {
        final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
        final unique = manifest['stats']?['uniqueQuestions'] ?? manifest['stats']?['questionsApprox'];
        if (unique != null) await _db.setSyncMeta('question_count', unique.toString());
      } catch (_) {}
    }
  }
  static Future<ExpectedContentStats> readExpectedStats(String dataPath) async {
    final manifestFile = File(p.join(dataPath, 'manifest.json'));
    if (!manifestFile.existsSync()) return ExpectedContentStats.fallback;
    try {
      final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      return ExpectedContentStats.fromManifest(manifest);
    } catch (_) {
      return ExpectedContentStats.fallback;
    }
  }

  static Future<int> countJsonTests(String dataPath) async {
    final testsDir = Directory(p.join(dataPath, 'tests'));
    if (!testsDir.existsSync()) return 0;
    var count = 0;
    await for (final entity in testsDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) count++;
    }
    return count;
  }
}

class ImportResult {
  final int laws;
  final int titles;
  final int tests;

  ImportResult({required this.laws, required this.titles, required this.tests});

  bool get isEmpty => laws == 0 && titles == 0 && tests == 0;
}

class ExpectedContentStats {
  const ExpectedContentStats({required this.laws, required this.tests});

  final int laws;
  final int tests;

  static const fallback = ExpectedContentStats(laws: 1, tests: 1);

  static ExpectedContentStats fromManifest(Map<String, dynamic> manifest) {
    final stats = manifest['stats'] as Map<String, dynamic>? ?? {};
    return ExpectedContentStats(
      laws: int.tryParse(stats['laws']?.toString() ?? '') ?? 1,
      tests: int.tryParse(stats['testsExported']?.toString() ?? stats['testIds']?.toString() ?? '') ?? 1,
    );
  }
}
