import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:testea_local/services/content_importer.dart';

import 'helpers/database_helper.dart';

void main() {
  group('ContentImporter', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('opotest_data_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('importFromDirectory carga leyes, títulos y tests', () async {
      final db = await setUpTestDatabase();
      addTearDown(tearDownTestDatabase);

      final dataDir = Directory(p.join(tempDir.path, 'temario'));
      await dataDir.create(recursive: true);

      await File(p.join(dataDir.path, 'laws-index.json')).writeAsString(
        jsonEncode({
          'laws': [
            {'id': '10', 'code': 'L10', 'name_es': 'Ley 10', 'order': '1'},
          ],
          'qByLawNew': {
            '10': {
              'mainLevel': {'test': ['1001']},
            },
          },
        }),
      );

      final titlesDir = Directory(p.join(dataDir.path, 'laws', '10', 'titles'));
      await titlesDir.create(recursive: true);
      await File(p.join(titlesDir.path, '82.json')).writeAsString(
        jsonEncode({
          'title': {'id': '82', 'code': 'T1', 'name_es': 'Título I', 'order': '1'},
          'arChapters': [],
          'arArticles': [],
          'qByTitle': {
            '82': {'mainLevel': ['1001'], 'subLevel': []},
          },
          'qByChapter': {},
          'qByArticle': {},
        }),
      );

      final testsDir = Directory(p.join(dataDir.path, 'tests'));
      await testsDir.create(recursive: true);
      await File(p.join(testsDir.path, '1001.json')).writeAsString(
        jsonEncode(sampleTestJson()),
      );

      final importer = ContentImporter(db);
      final result = await importer.importFromDirectory(dataDir.path);

      expect(result.laws, 1);
      expect(result.titles, 1);
      expect(result.tests, 1);
      expect(await db.countTests(), 1);
      expect(await db.countTitles(), 1);

      final laws = await db.getLaws();
      expect(laws, hasLength(1));
      expect(laws.first['code'], 'L10');
    });
  });
}
