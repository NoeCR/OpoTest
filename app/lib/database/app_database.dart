import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../features/in_progress_session/domain/in_progress_session.dart';
import '../features/profile_sync/domain/profile_sync_link.dart';
import '../features/spaced_review/domain/question_review_state.dart';
import '../features/spaced_review/domain/spaced_review_scheduler.dart';
import '../models/local_user.dart';
import '../models/marked_question.dart';
import '../models/question.dart';
import '../models/test_stats.dart';
import '../utils/qmap.dart';

class AppDatabase {
  static const testSourceOfficial = 'official';
  static const testSourceCustom = 'custom';
  static const _databaseFileName = 'opotest.db';
  static const _legacyDatabaseFileName = 'testea_local.db';
  static Database? _db;

  static Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _databaseFileName);
    await _migrateLegacyDatabaseIfNeeded(dir.path);
    _db = await _openDatabase(path);
  }

  /// Inicializa SQLite en memoria para tests (solo FFI).
  @visibleForTesting
  static Future<void> initForTest() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await disposeForTest();
    _db = await _openDatabase(inMemoryDatabasePath);
  }

  @visibleForTesting
  static Future<void> disposeForTest() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _migrateLegacyDatabaseIfNeeded(String dirPath) async {
    final current = File(p.join(dirPath, _databaseFileName));
    final legacy = File(p.join(dirPath, _legacyDatabaseFileName));
    if (current.existsSync() || !legacy.existsSync()) return;
    try {
      await legacy.rename(current.path);
    } catch (e) {
      debugPrint('No se pudo migrar la base local antigua: $e');
    }
  }

  static Future<Database> _openDatabase(String path) {
    return openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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
    await _createMarkedQuestionsTable(db);
    await _createInProgressSessionsTable(db);
    await _createRecoveredQuestionsTable(db);
    await _createQuestionReviewStateTable(db);
    await _createUserProfileSyncTable(db);
  }

  static Future<void> _createMarkedQuestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE marked_questions (
        user_id TEXT NOT NULL,
        test_id TEXT NOT NULL,
        question_index INTEGER NOT NULL,
        marked_at TEXT NOT NULL,
        PRIMARY KEY (user_id, test_id, question_index)
      )
    ''');
  }

  static Future<void> _createRecoveredQuestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE recovered_questions (
        user_id TEXT NOT NULL,
        test_id TEXT NOT NULL,
        question_index INTEGER NOT NULL,
        recovered_at TEXT NOT NULL,
        PRIMARY KEY (user_id, test_id, question_index)
      )
    ''');
  }

  static Future<void> _createQuestionReviewStateTable(Database db) async {
    await db.execute('''
      CREATE TABLE question_review_state (
        user_id TEXT NOT NULL,
        test_id TEXT NOT NULL,
        question_index INTEGER NOT NULL,
        box INTEGER NOT NULL,
        next_due TEXT NOT NULL,
        last_result INTEGER NOT NULL,
        PRIMARY KEY (user_id, test_id, question_index)
      )
    ''');
  }

  static Future<void> _createUserProfileSyncTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile_sync (
        user_id TEXT PRIMARY KEY,
        sync_id TEXT NOT NULL UNIQUE,
        token TEXT NOT NULL,
        last_synced_at TEXT,
        last_error TEXT
      )
    ''');
  }

  static Future<void> _createInProgressSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE in_progress_sessions (
        user_id TEXT PRIMARY KEY,
        test_id TEXT NOT NULL,
        test_name TEXT NOT NULL,
        payload TEXT NOT NULL,
        answers_json TEXT NOT NULL,
        current_index INTEGER NOT NULL,
        elapsed_seconds INTEGER NOT NULL,
        error_format INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        exam_simulation INTEGER NOT NULL,
        question_count INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE tests ADD COLUMN chapter_id TEXT DEFAULT ''");
      await db.execute("ALTER TABLE tests ADD COLUMN section_id TEXT DEFAULT ''");
      await db.execute("ALTER TABLE tests ADD COLUMN article_id TEXT DEFAULT ''");
      await db.execute(
        "ALTER TABLE tests ADD COLUMN source TEXT NOT NULL DEFAULT 'official'",
      );
    }
    if (oldVersion < 3) {
      await _createMarkedQuestionsTable(db);
    }
    if (oldVersion < 4) {
      await _createInProgressSessionsTable(db);
    }
    if (oldVersion < 5) {
      await _createRecoveredQuestionsTable(db);
    }
    if (oldVersion < 6) {
      await _createQuestionReviewStateTable(db);
    }
    if (oldVersion < 7) {
      await _createUserProfileSyncTable(db);
    }
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
    await db.delete('marked_questions', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('recovered_questions', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('question_review_state', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('in_progress_sessions', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('user_profile_sync', where: 'user_id = ?', whereArgs: [userId]);
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

  Future<void> upsertCustomLaw({
    required String id,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !id.startsWith('custom_law_')) return;

    await db.insert(
      'laws',
      {
        'id': id,
        'code': trimmed,
        'name': trimmed,
        'order_idx': 900000 + (DateTime.now().millisecondsSinceEpoch % 100000),
        'payload': jsonEncode({
          'id': id,
          'code': trimmed,
          'name_es': trimmed,
          'custom': true,
        }),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, List<String>>> customTestIdsGroupedByLaw() async {
    final rows = await db.query(
      'tests',
      columns: ['id', 'law_id'],
      where: 'source = ?',
      whereArgs: [testSourceCustom],
      orderBy: 'law_id, index_num',
    );
    final grouped = <String, List<String>>{};
    for (final row in rows) {
      final lawId = row['law_id']?.toString();
      if (lawId == null || lawId.isEmpty) continue;
      grouped.putIfAbsent(lawId, () => []).add(row['id'] as String);
    }
    return grouped;
  }

  Future<Map<String, List<String>>> allContentIdsGroupedByLaw() async {
    final grouped = await contentIdsGroupedByLaw();
    final customGrouped = await customTestIdsGroupedByLaw();
    for (final entry in customGrouped.entries) {
      grouped.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }
    return grouped;
  }

  Future<Map<String, dynamic>?> getTitle(String id) async {
    final rows = await db.query('titles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTitlesForLaw(String lawId) =>
      db.query('titles', where: 'law_id = ?', whereArgs: [lawId], orderBy: 'order_idx');

  Future<List<Map<String, dynamic>>> titlesWithLaw() {
    return db.rawQuery(
      '''
      SELECT t.id, t.law_id, t.code, t.name, l.code AS law_code, l.name AS law_name
      FROM titles t
      LEFT JOIN laws l ON l.id = t.law_id
      ORDER BY t.order_idx
      ''',
    );
  }

  Future<List<Map<String, dynamic>>> testsWithPlace() {
    return db.rawQuery(
      '''
      SELECT te.id, te.name, te.law_id, te.title_id,
             l.code AS law_code, l.name AS law_name, ti.name AS title_name
      FROM tests te
      LEFT JOIN laws l ON l.id = te.law_id
      LEFT JOIN titles ti ON ti.id = te.title_id
      ORDER BY te.index_num
      ''',
    );
  }

  Future<List<Map<String, dynamic>>> searchTestPayloadsContaining(
    String likePattern, {
    int limit = 80,
  }) {
    return db.rawQuery(
      '''
      SELECT te.id, te.name, te.law_id, te.title_id, te.payload,
             l.code AS law_code, l.name AS law_name, ti.name AS title_name
      FROM tests te
      LEFT JOIN laws l ON l.id = te.law_id
      LEFT JOIN titles ti ON ti.id = te.title_id
      WHERE LOWER(te.payload) LIKE ? ESCAPE '\\'
      LIMIT ?
      ''',
      [likePattern, limit],
    );
  }

  Future<TestDefinition?> getTest(String id) async {
    final rows = await db.query('tests', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final payload = jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
    return TestDefinition.fromApiJson(payload);
  }

  Future<String?> getTestLawId(String testId) async {
    final rows = await db.query(
      'tests',
      columns: ['law_id'],
      where: 'id = ?',
      whereArgs: [testId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final lawId = rows.first['law_id']?.toString() ?? '';
    return lawId.isEmpty ? null : lawId;
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
    final ids = allTestIdsForTitlePayload(titlePayload, titleId);
    if (ids.isNotEmpty) return ids;
    final chapters = mapsOf(titlePayload['arChapters']);
    final articles = articleTestGroups(titlePayload);
    if (chapters.isNotEmpty || articles.isNotEmpty) return [];
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
      columns: ['test_id', 'percent_score', 'finished_at'],
      where: 'user_id = ? AND test_id IN ($placeholders)',
      whereArgs: [userId, ...testIds],
      orderBy: 'finished_at ASC',
    );

    final byTest = <String, List<double>>{};
    final lastByTest = <String, double>{};
    for (final row in rows) {
      final id = row['test_id']?.toString();
      if (id == null) continue;
      final percent = (row['percent_score'] as num?)?.toDouble() ?? 0;
      (byTest[id] ??= []).add(percent);
      lastByTest[id] = percent;
    }

    for (final entry in byTest.entries) {
      final percents = entry.value;
      final avg = percents.reduce((a, b) => a + b) / percents.length;
      final best = percents.reduce((a, b) => a > b ? a : b);
      out[entry.key] = TestStats(
        avgPercent: avg,
        bestPercent: best,
        lastPercent: lastByTest[entry.key],
        attempts: percents.length,
      );
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
    await upsertAttempt(attempt);
  }

  Future<void> upsertAttempt(TestAttempt attempt) async {
    await db.insert(
      'attempts',
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> attemptsForUser(String userId, {String? testId}) async {
    return db.query(
      'attempts',
      where: testId == null ? 'user_id = ?' : 'user_id = ? AND test_id = ?',
      whereArgs: testId == null ? [userId] : [userId, testId],
      orderBy: 'finished_at DESC',
    );
  }

  Future<TestAttempt?> getAttempt(String id) async {
    final rows = await db.query('attempts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return TestAttempt.fromMap(rows.first);
  }

  Future<List<TestAttempt>> attemptsForUserModel(String userId, {String? testId}) async {
    final rows = await attemptsForUser(userId, testId: testId);
    return rows.map(TestAttempt.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> officialAttemptPoints(String userId) {
    return db.rawQuery(
      '''
      SELECT a.test_id, a.percent_score, a.finished_at, t.law_id, t.title_id
      FROM attempts a
      INNER JOIN tests t ON t.id = a.test_id
      WHERE a.user_id = ?
      ORDER BY a.finished_at ASC
      ''',
      [userId],
    );
  }

  /// Devuelve IDs de tests disponibles en el temario local.
  Future<List<String>> getAllTestIds() async {
    final rows = await db.query(
      'tests',
      columns: ['id'],
      where: 'source != ? OR source IS NULL',
      whereArgs: [testSourceCustom],
      orderBy: 'index_num',
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Devuelve IDs de tests propios (creados por el usuario).
  Future<List<String>> getAllCustomTestIds() async {
    final rows = await db.query(
      'tests',
      columns: ['id'],
      where: 'source = ?',
      whereArgs: [testSourceCustom],
      orderBy: 'index_num',
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  Future<List<({String id, String lawId, String name})>> getOfficialTestsMeta({
    List<String>? types,
  }) async {
    final args = <Object>[testSourceOfficial];
    var typeClause = '';
    if (types != null && types.isNotEmpty) {
      typeClause = ' AND type IN (${List.filled(types.length, '?').join(', ')})';
      args.addAll(types);
    }
    final rows = await db.query(
      'tests',
      columns: ['id', 'law_id', 'name'],
      where: '(source = ? OR source IS NULL)$typeClause',
      whereArgs: args,
      orderBy: 'index_num',
    );
    return rows
        .map(
          (r) => (
            id: r['id'] as String,
            lawId: r['law_id']?.toString() ?? '',
            name: r['name']?.toString() ?? 'Test',
          ),
        )
        .toList();
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

  /// IDs de tests temario (`type = test`) agrupados por ley.
  Future<Map<String, List<String>>> testIdsGroupedByLaw() async {
    return _idsGroupedByLaw(types: const ['test']);
  }

  /// IDs de todo el contenido practicable (tests, exámenes y oficiales) por ley.
  Future<Map<String, List<String>>> contentIdsGroupedByLaw() async {
    return _idsGroupedByLaw(types: const ['test', 'exam', 'realexam']);
  }

  Future<Map<String, List<String>>> _idsGroupedByLaw({required List<String> types}) async {
    final placeholders = List.filled(types.length, '?').join(', ');
    final rows = await db.query(
      'tests',
      columns: ['id', 'law_id'],
      where: 'type IN ($placeholders)',
      whereArgs: types,
      orderBy: 'law_id, index_num, CAST(id AS INTEGER)',
    );
    final grouped = <String, List<String>>{};
    for (final row in rows) {
      final lawId = row['law_id']?.toString();
      if (lawId == null || lawId.isEmpty) continue;
      grouped.putIfAbsent(lawId, () => []).add(row['id'] as String);
    }
    return grouped;
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
    if (node == null) return [];

    final main = node['mainLevel'];
    if (main is Map) {
      final list = main[type];
      if (list is List && list.isNotEmpty) {
        return list.map((e) => e.toString()).toList();
      }
    } else if (main is List && type == 'test') {
      return main.map((e) => e.toString()).toList();
    }

    // Constitución y otras leyes pueden listar tests en subLevel sin bucket mainLevel.test.
    if (type == 'test') {
      final sub = node['subLevel'];
      if (sub is List && sub.isNotEmpty) {
        return sub.map((e) => e.toString()).toList();
      }
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

  // --- Tests propios (source = custom) ---

  Future<void> upsertCustomTest(Map<String, dynamic> json) async {
    final def = TestDefinition.fromApiJson(json);
    if (def.id.isEmpty) return;

    final testMap = json['test'] as Map<String, dynamic>? ?? {};
    await db.insert(
      'tests',
      {
        'id': def.id,
        'title_id': '',
        'law_id': testMap['idLaw']?.toString() ?? '',
        'chapter_id': '',
        'section_id': '',
        'article_id': '',
        'name': def.name,
        'type': testMap['type']?.toString() ?? 'own',
        'source': testSourceCustom,
        'index_num': DateTime.now().millisecondsSinceEpoch,
        'payload': jsonEncode(json),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _invalidateQuestionCountCache();
  }

  Future<void> deleteCustomTest(String testId) async {
    await db.delete('attempts', where: 'test_id = ?', whereArgs: [testId]);
    await db.delete(
      'tests',
      where: 'id = ? AND source = ?',
      whereArgs: [testId, testSourceCustom],
    );
    await _invalidateQuestionCountCache();
  }

  Future<Map<String, dynamic>?> getCustomTestRow(String testId) async {
    final rows = await db.query(
      'tests',
      where: 'id = ? AND source = ?',
      whereArgs: [testId, testSourceCustom],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _customTestRowFromDb(rows.first);
  }

  Future<List<Map<String, dynamic>>> listCustomTestRows({String? lawId}) async {
    final rows = await db.query(
      'tests',
      where: lawId == null ? 'source = ?' : 'source = ? AND law_id = ?',
      whereArgs: lawId == null ? [testSourceCustom] : [testSourceCustom, lawId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(_customTestRowFromDb).toList();
  }

  Map<String, dynamic> _customTestRowFromDb(Map<String, dynamic> row) {
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    final test = payload['test'] as Map<String, dynamic>? ?? {};
    return {
      'id': row['id'] as String,
      'law_id': row['law_id'] as String,
      'law_code': test['law_code']?.toString() ?? '',
      'payload': payload,
    };
  }

  Future<void> _invalidateQuestionCountCache() async {
    await db.delete('sync_meta', where: 'key = ?', whereArgs: ['question_count']);
  }

  // --- Copias de seguridad (export/import) ---

  Future<List<Map<String, dynamic>>> getAllAttempts() async {
    return db.query('attempts', orderBy: 'finished_at DESC');
  }

  Future<Map<String, dynamic>> exportContentSnapshot() async {
    final laws = await db.query('laws', orderBy: 'order_idx');
    final titles = await db.query('titles', orderBy: 'order_idx');
    final tests = await db.query('tests', orderBy: 'index_num');
    final qByLaw = await getSyncMeta('q_by_law');
    final questionCount = await getSyncMeta('question_count');

    Map<String, dynamic>? decodePayload(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    final officialCount = tests.where((t) => t['source'] != testSourceCustom).length;
    final customCount = tests.where((t) => t['source'] == testSourceCustom).length;

    return {
      'laws': laws
          .map(
            (row) => {
              'id': row['id'],
              'code': row['code'],
              'name': row['name'],
              'order_idx': row['order_idx'],
              'payload': decodePayload(row['payload'] as String?) ?? {},
            },
          )
          .toList(),
      'titles': titles
          .map(
            (row) => {
              'id': row['id'],
              'law_id': row['law_id'],
              'code': row['code'],
              'name': row['name'],
              'order_idx': row['order_idx'],
              'payload': decodePayload(row['payload'] as String?) ?? {},
            },
          )
          .toList(),
      'tests': tests
          .map(
            (row) => {
              'id': row['id'],
              'title_id': row['title_id'],
              'law_id': row['law_id'],
              'chapter_id': row['chapter_id'],
              'section_id': row['section_id'],
              'article_id': row['article_id'],
              'name': row['name'],
              'type': row['type'],
              'source': row['source'],
              'index_num': row['index_num'],
              'payload': decodePayload(row['payload'] as String?) ?? {},
            },
          )
          .toList(),
      'sync_meta': {
        if (qByLaw != null) 'q_by_law': jsonDecode(qByLaw),
        if (questionCount != null) 'question_count': questionCount,
      },
      'stats': {
        'laws': laws.length,
        'titles': titles.length,
        'tests_official': officialCount,
        'tests_custom': customCount,
      },
    };
  }

  Future<Map<String, int>> importContentSnapshot(Map<String, dynamic> backup) async {
    var laws = 0;
    var titles = 0;
    var testsOfficial = 0;
    var testsCustom = 0;
    var testsSkipped = 0;

    for (final raw in backup['laws'] as List? ?? []) {
      final row = Map<String, dynamic>.from(raw as Map);
      await db.insert(
        'laws',
        {
          'id': row['id'].toString(),
          'code': row['code']?.toString() ?? '',
          'name': row['name']?.toString() ?? '',
          'order_idx': (row['order_idx'] as num?)?.toInt() ?? 0,
          'payload': jsonEncode(row['payload'] ?? {}),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      laws++;
    }

    for (final raw in backup['titles'] as List? ?? []) {
      final row = Map<String, dynamic>.from(raw as Map);
      await db.insert(
        'titles',
        {
          'id': row['id'].toString(),
          'law_id': row['law_id']?.toString() ?? '',
          'code': row['code']?.toString() ?? '',
          'name': row['name']?.toString() ?? '',
          'order_idx': (row['order_idx'] as num?)?.toInt() ?? 0,
          'payload': jsonEncode(row['payload'] ?? {}),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      titles++;
    }

    for (final raw in backup['tests'] as List? ?? []) {
      final row = Map<String, dynamic>.from(raw as Map);
      final payload = Map<String, dynamic>.from(row['payload'] as Map? ?? {});
      final source = row['source']?.toString() ?? testSourceOfficial;
      if (source == testSourceCustom) {
        await upsertCustomTest(payload);
        testsCustom++;
      } else {
        final inserted = await upsertOfficialTest(payload);
        if (inserted) {
          testsOfficial++;
        } else {
          testsSkipped++;
        }
      }
    }

    final meta = backup['sync_meta'] as Map<String, dynamic>? ?? {};
    final qByLaw = meta['q_by_law'];
    if (qByLaw != null) {
      await setSyncMeta('q_by_law', jsonEncode(qByLaw));
    }
    final questionCount = meta['question_count'];
    if (questionCount != null) {
      await setSyncMeta('question_count', questionCount.toString());
    } else {
      await _invalidateQuestionCountCache();
    }

    return {
      'laws': laws,
      'titles': titles,
      'tests_official': testsOfficial,
      'tests_custom': testsCustom,
      'tests_skipped': testsSkipped,
    };
  }

  Future<Map<String, dynamic>> exportProgressSnapshot({String? userId}) async {
    final users = userId == null
        ? await getUsers()
        : (await getUsers()).where((u) => u.id == userId).toList();
    final attempts = userId == null
        ? await getAllAttempts()
        : await attemptsForUser(userId);
    final activeId = await activeUserId();

    return {
      'users': users.map((u) => u.toMap()).toList(),
      'active_user_id': activeId,
      'attempts': attempts,
      'marked_questions': await _markedQuestionsForExport(userId),
      'recovered_questions': await _recoveredQuestionsForExport(userId),
      'question_review_states': await _questionReviewsForExport(userId),
    };
  }

  Future<List<Map<String, dynamic>>> _markedQuestionsForExport(String? userId) async {
    final rows = userId == null
        ? await db.query('marked_questions', orderBy: 'marked_at DESC')
        : await db.query(
            'marked_questions',
            where: 'user_id = ?',
            whereArgs: [userId],
            orderBy: 'marked_at DESC',
          );
    return rows;
  }

  Future<int> countMarkedQuestions(String userId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM marked_questions WHERE user_id = ?',
      [userId],
    );
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<List<MarkedQuestion>> markedQuestionsForUser(String userId) async {
    final rows = await db.query(
      'marked_questions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'marked_at DESC',
    );
    return rows.map((r) => MarkedQuestion.fromMap(r)).toList();
  }

  Future<Set<int>> markedQuestionIndices(String userId, String testId) async {
    final rows = await db.query(
      'marked_questions',
      columns: ['question_index'],
      where: 'user_id = ? AND test_id = ?',
      whereArgs: [userId, testId],
    );
    return rows.map((r) => (r['question_index'] as num).toInt()).toSet();
  }

  Future<bool> isQuestionMarked(String userId, String testId, int questionIndex) async {
    final rows = await db.query(
      'marked_questions',
      where: 'user_id = ? AND test_id = ? AND question_index = ?',
      whereArgs: [userId, testId, questionIndex],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> toggleMarkedQuestion({
    required String userId,
    required String testId,
    required int questionIndex,
  }) async {
    final exists = await isQuestionMarked(userId, testId, questionIndex);
    if (exists) {
      await db.delete(
        'marked_questions',
        where: 'user_id = ? AND test_id = ? AND question_index = ?',
        whereArgs: [userId, testId, questionIndex],
      );
      return false;
    }
    await db.insert(
      'marked_questions',
      MarkedQuestion(
        userId: userId,
        testId: testId,
        questionIndex: questionIndex,
        markedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  Future<Map<String, DateTime>> recoveredQuestionsForUser(String userId) async {
    final rows = await db.query(
      'recovered_questions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final out = <String, DateTime>{};
    for (final row in rows) {
      final testId = row['test_id'] as String? ?? '';
      final index = (row['question_index'] as num?)?.toInt();
      final at = DateTime.tryParse(row['recovered_at'] as String? ?? '');
      if (testId.isEmpty || index == null || at == null) continue;
      out['$testId:$index'] = at;
    }
    return out;
  }

  Future<void> applyOriginAnswerOutcomes({
    required String userId,
    required List<OriginAnswer> outcomes,
    required DateTime at,
  }) async {
    if (outcomes.isEmpty) return;
    final batch = db.batch();
    for (final outcome in outcomes) {
      if (outcome.correct) {
        batch.insert(
          'recovered_questions',
          {
            'user_id': userId,
            'test_id': outcome.testId,
            'question_index': outcome.questionIndex,
            'recovered_at': at.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        batch.delete(
          'recovered_questions',
          where: 'user_id = ? AND test_id = ? AND question_index = ?',
          whereArgs: [userId, outcome.testId, outcome.questionIndex],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> _recoveredQuestionsForExport(String? userId) async {
    return userId == null
        ? db.query('recovered_questions', orderBy: 'recovered_at DESC')
        : db.query(
            'recovered_questions',
            where: 'user_id = ?',
            whereArgs: [userId],
            orderBy: 'recovered_at DESC',
          );
  }

  Future<List<QuestionReviewState>> questionReviewsForUser(String userId) async {
    final rows = await db.query(
      'question_review_state',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map(QuestionReviewState.fromMap).toList();
  }

  Future<void> upsertQuestionReviews(Iterable<QuestionReviewState> states) async {
    if (states.isEmpty) return;
    final batch = db.batch();
    for (final state in states) {
      batch.insert(
        'question_review_state',
        state.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> countDueQuestionReviews(String userId, DateTime now) async {
    final today = SpacedReviewScheduler.calendarDay(now).toIso8601String();
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c
      FROM question_review_state
      WHERE user_id = ? AND next_due <= ?
      ''',
      [userId, today],
    );
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<List<QuestionReviewState>> dueQuestionReviews(String userId, DateTime now) async {
    final today = SpacedReviewScheduler.calendarDay(now).toIso8601String();
    final rows = await db.query(
      'question_review_state',
      where: 'user_id = ? AND next_due <= ?',
      whereArgs: [userId, today],
      orderBy: 'next_due',
    );
    return rows.map(QuestionReviewState.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> _questionReviewsForExport(String? userId) async {
    return userId == null
        ? db.query('question_review_state', orderBy: 'next_due')
        : db.query(
            'question_review_state',
            where: 'user_id = ?',
            whereArgs: [userId],
            orderBy: 'next_due',
          );
  }

  Future<void> upsertInProgressSession(InProgressSession session) async {
    await db.insert(
      'in_progress_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<InProgressSession?> getInProgressSession(String userId) async {
    final rows = await db.query(
      'in_progress_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return InProgressSession.fromMap(rows.first);
  }

  Future<void> deleteInProgressSession(String userId) async {
    await db.delete(
      'in_progress_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, int>> importProgressSnapshot(
    Map<String, dynamic> backup, {
    bool replaceExistingUsers = false,
  }) async {
    var users = 0;
    var attempts = 0;
    var missingTests = 0;
    var markedQuestions = 0;
    var recoveredQuestions = 0;
    var questionReviews = 0;

    final userRows = backup['users'] as List? ?? [];
    if (backup['user'] is Map && userRows.isEmpty) {
      userRows.add(backup['user']);
    }

    for (final raw in userRows) {
      final map = Map<String, dynamic>.from(raw as Map);
      final user = LocalUser.fromMap(map);
      if (replaceExistingUsers) {
        await db.delete('attempts', where: 'user_id = ?', whereArgs: [user.id]);
        await db.delete('marked_questions', where: 'user_id = ?', whereArgs: [user.id]);
        await db.delete('recovered_questions', where: 'user_id = ?', whereArgs: [user.id]);
        await db.delete('question_review_state', where: 'user_id = ?', whereArgs: [user.id]);
        await db.delete('in_progress_sessions', where: 'user_id = ?', whereArgs: [user.id]);
      }
      await upsertUser(user);
      users++;
    }

    final attemptRows = backup['attempts'] as List? ?? [];
    final knownTests = {
      for (final row in await db.query('tests', columns: ['id'])) row['id'] as String,
    };

    for (final raw in attemptRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final attempt = _attemptFromBackupRow(row);
      if (!knownTests.contains(attempt.testId)) missingTests++;
      await upsertAttempt(attempt);
      attempts++;
    }

    final activeId = backup['active_user_id']?.toString();
    if (activeId != null && activeId.isNotEmpty) {
      await setActiveUserId(activeId);
    }

    final markedRows = backup['marked_questions'] as List? ?? [];
    for (final raw in markedRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final marked = MarkedQuestion.fromMap(row);
      if (!knownTests.contains(marked.testId)) missingTests++;
      await db.insert(
        'marked_questions',
        marked.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      markedQuestions++;
    }

    final recoveredRows = backup['recovered_questions'] as List? ?? [];
    for (final raw in recoveredRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final testId = row['test_id']?.toString() ?? '';
      if (testId.isNotEmpty && !knownTests.contains(testId)) missingTests++;
      await db.insert(
        'recovered_questions',
        {
          'user_id': row['user_id'],
          'test_id': testId,
          'question_index': row['question_index'],
          'recovered_at': row['recovered_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      recoveredQuestions++;
    }

    final reviewRows = backup['question_review_states'] as List? ?? [];
    for (final raw in reviewRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final state = QuestionReviewState.fromMap(row);
      if (state.testId.isNotEmpty && !knownTests.contains(state.testId)) missingTests++;
      await db.insert(
        'question_review_state',
        state.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      questionReviews++;
    }

    return {
      'users': users,
      'attempts': attempts,
      'missing_tests': missingTests,
      'marked_questions': markedQuestions,
      'recovered_questions': recoveredQuestions,
      'question_review_states': questionReviews,
    };
  }

  Future<ProfileSyncLink?> profileSyncLinkForUser(String userId) async {
    final rows = await db.query(
      'user_profile_sync',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProfileSyncLink.fromMap(rows.first);
  }

  Future<ProfileSyncLink?> profileSyncLinkForSyncId(String syncId) async {
    final rows = await db.query(
      'user_profile_sync',
      where: 'sync_id = ?',
      whereArgs: [syncId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProfileSyncLink.fromMap(rows.first);
  }

  Future<void> upsertProfileSyncLink(ProfileSyncLink link) async {
    await db.insert(
      'user_profile_sync',
      link.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProfileSyncLink(String userId) async {
    await db.delete('user_profile_sync', where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Incorpora progreso ya remapeado al [userId] local. No cambia de usuario activo ni crea cuentas.
  Future<void> mergeProgressForUser({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final attemptRows = payload['attempts'] as List? ?? [];
    for (final raw in attemptRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      row['user_id'] = userId;
      final attempt = _attemptFromBackupRow(row);
      await db.insert(
        'attempts',
        {
          'id': attempt.id,
          'user_id': userId,
          'test_id': attempt.testId,
          'test_name': attempt.testName,
          'finished_at': attempt.finishedAt.toIso8601String(),
          'duration_seconds': attempt.durationSeconds,
          'net_score': attempt.netScore,
          'percent_score': attempt.percentScore,
          'answers_json': jsonEncode(attempt.answers.map((k, v) => MapEntry(k.toString(), v))),
          'exam_simulation': attempt.examSimulation ? 1 : 0,
          'error_format': attempt.errorFormat,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final markedRows = payload['marked_questions'] as List? ?? [];
    for (final raw in markedRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      row['user_id'] = userId;
      await db.insert(
        'marked_questions',
        MarkedQuestion.fromMap(row).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final recoveredRows = payload['recovered_questions'] as List? ?? [];
    for (final raw in recoveredRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      await db.insert(
        'recovered_questions',
        {
          'user_id': userId,
          'test_id': row['test_id'],
          'question_index': row['question_index'],
          'recovered_at': row['recovered_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final reviewRows = payload['question_review_states'] as List? ?? [];
    for (final raw in reviewRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      row['user_id'] = userId;
      await db.insert(
        'question_review_state',
        QuestionReviewState.fromMap(row).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  TestAttempt _attemptFromBackupRow(Map<String, dynamic> row) => TestAttempt.fromMap(row);
}
