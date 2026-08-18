import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/local_user.dart';
import '../models/question.dart';
import '../models/test_stats.dart';
import '../utils/qmap.dart';

class AppDatabase {
  static const testSourceOfficial = 'official';
  static const testSourceCustom = 'custom';
  static Database? _db;

  static Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'testea_local.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE laws (
            id TEXT PRIMARY KEY,
            code TEXT,
            name TEXT,
            order_idx INTEGER,
            payload TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE titles (
            id TEXT PRIMARY KEY,
            law_id TEXT,
            code TEXT,
            name TEXT,
            order_idx INTEGER,
            payload TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tests (
            id TEXT PRIMARY KEY,
            title_id TEXT,
            law_id TEXT,
            chapter_id TEXT,
            section_id TEXT,
            article_id TEXT,
            name TEXT,
            type TEXT,
            source TEXT NOT NULL DEFAULT 'official',
            index_num INTEGER,
            payload TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE attempts (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            test_id TEXT,
            test_name TEXT,
            finished_at TEXT,
            duration_seconds INTEGER,
            net_score REAL,
            percent_score REAL,
            answers_json TEXT,
            exam_simulation INTEGER,
            error_format INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_meta (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tests ADD COLUMN chapter_id TEXT DEFAULT ''");
          await db.execute("ALTER TABLE tests ADD COLUMN section_id TEXT DEFAULT ''");
          await db.execute("ALTER TABLE tests ADD COLUMN article_id TEXT DEFAULT ''");
          await db.execute(
            "ALTER TABLE tests ADD COLUMN source TEXT NOT NULL DEFAULT 'official'",
          );
        }
      },
    );
  }

  static Database get db {
    final d = _db;
    if (d == null) throw StateError('Database not initialized');
    return d;
  }

  Future<List<LocalUser>> getUsers() async {
    final rows = await db.query('users', orderBy: 'created_at');
    return rows.map((r) => LocalUser.fromMap(r)).toList();
  }

  Future<void> upsertUser(LocalUser user) async {
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteUserData(String userId) async {
    await db.delete('attempts', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<String?> activeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_user_id');
  }

  Future<void> setActiveUserId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('active_user_id');
    } else {
      await prefs.setString('active_user_id', id);
    }
  }

  Future<void> importLawIndex(Map<String, dynamic> lawsIndex) async {
    final laws = lawsIndex['laws'] as List? ?? [];
    final batch = db.batch();
    for (final raw in laws) {
      final law = raw as Map<String, dynamic>;
      batch.insert(
        'laws',
        {
          'id': law['id'].toString(),
          'code': law['code']?.toString() ?? '',
          'name': law['name_es']?.toString() ?? '',
          'order_idx': int.tryParse(law['order']?.toString() ?? '0') ?? 0,
          'payload': jsonEncode(law),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    final qByLaw = lawsIndex['qByLawNew'];
    if (qByLaw != null) {
      await setSyncMeta('q_by_law', jsonEncode(qByLaw));
    }
  }

  Future<void> importTitle(String lawId, Map<String, dynamic> titleData) async {
    final title = titleData['title'] as Map<String, dynamic>? ?? {};
    await db.insert(
      'titles',
      {
        'id': title['id'].toString(),
        'law_id': lawId,
        'code': title['code']?.toString() ?? '',
        'name': title['name_es']?.toString() ?? '',
        'order_idx': int.tryParse(title['order']?.toString() ?? '0') ?? 0,
        'payload': jsonEncode(titleData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> importTestFile(String filePath) async {
    final json = jsonDecode(await File(filePath).readAsString()) as Map<String, dynamic>;
    final def = TestDefinition.fromApiJson(json);
    final testMap = json['test'] as Map<String, dynamic>? ?? {};
    await db.insert(
      'tests',
      {
        'id': def.id,
        'title_id': testMap['idTitle']?.toString() ?? '',
        'law_id': testMap['idLaw']?.toString() ?? '',
        'chapter_id': testMap['idChapter']?.toString() ?? '',
        'section_id': testMap['idSection']?.toString() ?? '',
        'article_id': testMap['idArticle']?.toString() ?? '',
        'name': def.name,
        'type': def.type,
        'source': testSourceOfficial,
        'index_num': int.tryParse(testMap['index']?.toString() ?? '0') ?? 0,
        'payload': jsonEncode(json),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert no-destructivo para catálogo oficial.
  /// Si un test existe como `custom`, se respeta y no se pisa.
  Future<bool> upsertOfficialTest(Map<String, dynamic> json) async {
    final def = TestDefinition.fromApiJson(json);
    if (def.id.isEmpty) return false;

    final existing = await db.query(
      'tests',
      columns: ['source'],
      where: 'id = ?',
      whereArgs: [def.id],
      limit: 1,
    );
    if (existing.isNotEmpty &&
        (existing.first['source']?.toString() ?? testSourceOfficial) == testSourceCustom) {
      return false;
    }

    final testMap = json['test'] as Map<String, dynamic>? ?? {};
    await db.insert(
      'tests',
      {
        'id': def.id,
        'title_id': testMap['idTitle']?.toString() ?? '',
        'law_id': testMap['idLaw']?.toString() ?? '',
        'chapter_id': testMap['idChapter']?.toString() ?? '',
        'section_id': testMap['idSection']?.toString() ?? '',
        'article_id': testMap['idArticle']?.toString() ?? '',
        'name': def.name,
        'type': def.type,
        'source': testSourceOfficial,
        'index_num': int.tryParse(testMap['index']?.toString() ?? '0') ?? 0,
        'payload': jsonEncode(json),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  Future<List<Map<String, dynamic>>> getLaws() =>
      db.query('laws', orderBy: 'order_idx');

  Future<Map<String, dynamic>?> getTitle(String id) async {
    final rows = await db.query('titles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTitlesForLaw(String lawId) =>
      db.query('titles', where: 'law_id = ?', whereArgs: [lawId], orderBy: 'order_idx');

  Future<TestDefinition?> getTest(String id) async {
    final rows = await db.query('tests', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final payload = jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
    return TestDefinition.fromApiJson(payload);
  }

  Future<Map<String, dynamic>?> getChapterPayload(String lawId, String titleId, String chapterId) async {
    final base = await getSyncMeta('content_path');
    if (base == null) return null;
    final file = File(p.join(base, 'laws', lawId, 'titles', titleId, 'chapters', '$chapterId.json'));
    if (!file.existsSync()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<List<String>> testIdsForTitle(String titleId, Map<String, dynamic>? titlePayload) async {
    if (titlePayload == null) return [];
    final chapters = mapsOf(titlePayload['arChapters']);
    final articles = articleTestGroups(titlePayload);
    if (chapters.isNotEmpty || articles.isNotEmpty) return [];
    final ids = testIdsFromQMap(titlePayload['qByTitle'], titleId);
    if (ids.isNotEmpty) return ids;
    if (asStringMap(titlePayload['qByChapter'])?.isNotEmpty ?? false) return [];
    final rows = await db.query('tests', where: 'title_id = ?', whereArgs: [titleId]);
    return rows.map((r) => r['id'] as String).toList();
  }

  Future<List<String>> testIdsForChapter(String chapterId, Map<String, dynamic>? chapterPayload) async {
    if (chapterPayload != null) {
      final ids = testIdsFromQMap(chapterPayload['qByChapter'], chapterId, includeSubLevel: true);
      if (ids.isNotEmpty) return ids;
    }
    return _testIdsForChapterFromDb(chapterId);
  }

  Future<List<String>> _testIdsForChapterFromDb(String chapterId) async {
    final rows = await db.query('tests', columns: ['id', 'payload'], orderBy: 'index_num');
    final ids = <String>[];
    for (final row in rows) {
      try {
        final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        final test = json['test'] as Map<String, dynamic>? ?? {};
        if (test['idChapter']?.toString() == chapterId) {
          ids.add(row['id'] as String);
        }
      } catch (_) {}
    }
    return ids;
  }

  Future<Set<String>> attemptedTestIds(String userId) async {
    final rows = await db.query(
      'attempts',
      columns: ['test_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows
        .map((r) => r['test_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<TestStats> statsForTest(String userId, String testId) async {
    final map = await statsForTests(userId, [testId]);
    return map[testId] ?? const TestStats();
  }

  Future<Map<String, TestStats>> statsForTests(String userId, List<String> testIds) async {
    final out = <String, TestStats>{
      for (final id in testIds) id: const TestStats(),
    };
    if (testIds.isEmpty) return out;

    final placeholders = List.filled(testIds.length, '?').join(',');
    final rows = await db.query(
      'attempts',
      columns: ['test_id', 'percent_score'],
      where: 'user_id = ? AND test_id IN ($placeholders)',
      whereArgs: [userId, ...testIds],
    );

    final byTest = <String, List<double>>{};
    for (final row in rows) {
      final id = row['test_id']?.toString();
      if (id == null) continue;
      final percent = (row['percent_score'] as num?)?.toDouble() ?? 0;
      (byTest[id] ??= []).add(percent);
    }

    for (final entry in byTest.entries) {
      final percents = entry.value;
      final avg = percents.reduce((a, b) => a + b) / percents.length;
      final best = percents.reduce((a, b) => a > b ? a : b);
      out[entry.key] = TestStats(avgPercent: avg, bestPercent: best, attempts: percents.length);
    }
    return out;
  }

  Future<Map<String, dynamic>?> getLastAttempt(String userId) async {
    final rows = await attemptsForUser(userId);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> countQuestions() async {
    final cached = await getSyncMeta('question_count');
    if (cached != null) return int.tryParse(cached) ?? 0;
    var total = 0;
    final rows = await db.query('tests', columns: ['payload']);
    for (final row in rows) {
      try {
        final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        final def = TestDefinition.fromApiJson(json);
        total += def.questions.length;
      } catch (_) {}
    }
    await setSyncMeta('question_count', total.toString());
    return total;
  }

  Future<String?> getTestName(String testId) async {
    final rows = await db.query('tests', columns: ['name'], where: 'id = ?', whereArgs: [testId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['name'] as String?;
  }

  Future<void> saveAttempt(TestAttempt attempt) async {
    await db.insert('attempts', {
      'id': attempt.id,
      'user_id': attempt.userId,
      'test_id': attempt.testId,
      'test_name': attempt.testName,
      'finished_at': attempt.finishedAt.toIso8601String(),
      'duration_seconds': attempt.durationSeconds,
      'net_score': attempt.netScore,
      'percent_score': attempt.percentScore,
      'answers_json': jsonEncode(attempt.answers.map((k, v) => MapEntry(k.toString(), v))),
      'exam_simulation': attempt.examSimulation ? 1 : 0,
      'error_format': attempt.errorFormat,
    });
  }

  Future<List<Map<String, dynamic>>> attemptsForUser(String userId, {String? testId}) async {
    return db.query(
      'attempts',
      where: testId == null ? 'user_id = ?' : 'user_id = ? AND test_id = ?',
      whereArgs: testId == null ? [userId] : [userId, testId],
      orderBy: 'finished_at DESC',
    );
  }

  /// Devuelve IDs de tests disponibles en el temario local.
  Future<List<String>> getAllTestIds() async {
    final rows = await db.query('tests', columns: ['id'], orderBy: 'index_num');
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Nombre del título (sección) al que pertenece un test.
  Future<String?> getTitleNameForTest(String testId) async {
    final rows = await db.rawQuery(
      '''
      SELECT titles.name as title_name
      FROM tests
      LEFT JOIN titles ON titles.id = tests.title_id
      WHERE tests.id = ?
      LIMIT 1
      ''',
      [testId],
    );
    if (rows.isEmpty) return null;
    return rows.first['title_name'] as String?;
  }

  Future<List<String>> testIdsForLawType(String lawId, String type) async {
    final fromIndex = await _qByLawTypeIds(lawId, type);
    if (fromIndex.isNotEmpty) return fromIndex;
    final rows = await db.query(
      'tests',
      columns: ['id'],
      where: 'law_id = ? AND type = ?',
      whereArgs: [lawId, type],
      orderBy: 'index_num, CAST(id AS INTEGER)',
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  Future<List<String>> testIdsForLawSource(String lawId, String source) async {
    final rows = await db.query(
      'tests',
      columns: ['id'],
      where: 'law_id = ? AND source = ?',
      whereArgs: [lawId, source],
      orderBy: 'index_num, CAST(id AS INTEGER)',
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  Future<List<String>> _qByLawTypeIds(String lawId, String type) async {
    final qByLaw = await _qByLawMap();
    final node = asStringMap(qByLaw?[lawId]);
    final main = node?['mainLevel'];
    if (main is Map) {
      final list = main[type];
      if (list is List) return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> _qByLawMap() async {
    final cached = await getSyncMeta('q_by_law');
    if (cached != null && cached.isNotEmpty) {
      try {
        return jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
    final base = await getSyncMeta('content_path');
    if (base == null) return null;
    final file = File(p.join(base, 'laws-index.json'));
    if (!file.existsSync()) return null;
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final q = data['qByLawNew'];
      if (q is Map) {
        final map = Map<String, dynamic>.from(q);
        await setSyncMeta('q_by_law', jsonEncode(map));
        return map;
      }
    } catch (_) {}
    return null;
  }

  Future<void> setSyncMeta(String key, String value) async {
    await db.insert('sync_meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> countTests() async {
    final row = await db.rawQuery('SELECT COUNT(*) AS c FROM tests');
    return (row.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> countTitles() async {
    final row = await db.rawQuery('SELECT COUNT(*) AS c FROM titles');
    return (row.first['c'] as num?)?.toInt() ?? 0;
  }

  Batch newBatch() => db.batch();

  Future<String?> getSyncMeta(String key) async {
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
