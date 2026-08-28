import 'dart:convert';

import '../../../database/app_database.dart';
import '../../../models/question.dart';
import '../domain/temario_search.dart';

class TemarioSearchService {
  TemarioSearchService(this._db);

  final AppDatabase _db;

  Future<TemarioSearchResults> search(String rawQuery) async {
    final query = normalizeSearchQuery(rawQuery);
    if (query.length < temarioSearchMinQueryLength) {
      return TemarioSearchResults.empty;
    }
    final sanitized = sanitizeLikeQuery(query);
    if (sanitized.length < temarioSearchMinQueryLength) {
      return TemarioSearchResults.empty;
    }
    final like = likeContainsPattern(sanitized);

    final lawRows = await _db.getLaws();
    final titleRows = await _db.titlesWithLaw();
    final testRows = await _db.testsWithPlace();
    final payloadRows = await _db.searchTestPayloadsContaining(like);

    return TemarioSearchResults(
      laws: sortedSearchHits(_hitsFromLaws(query, lawRows)),
      titles: sortedSearchHits(_hitsFromTitles(query, titleRows)),
      tests: sortedSearchHits(_hitsFromTests(query, testRows)),
      questions: sortedSearchHits(_hitsFromQuestions(query, payloadRows)),
    );
  }

  Iterable<TemarioSearchHit> _hitsFromLaws(
    String query,
    List<Map<String, dynamic>> rows,
  ) sync* {
    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final code = row['code']?.toString() ?? '';
      final name = row['name']?.toString() ?? '';
      final rank = rankSearchFields(query, [name, code]);
      if (rank == null) continue;
      final title = code.isNotEmpty ? code : name;
      yield TemarioSearchHit(
        kind: TemarioSearchKind.law,
        id: id,
        title: title,
        subtitle: name.isNotEmpty && name != title ? name : null,
        rank: rank,
        lawId: id,
        lawCode: code,
        lawName: name,
      );
    }
  }

  Iterable<TemarioSearchHit> _hitsFromTitles(
    String query,
    List<Map<String, dynamic>> rows,
  ) sync* {
    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final code = row['code']?.toString() ?? '';
      final name = row['name']?.toString() ?? '';
      final rank = rankSearchFields(query, [name, code]);
      if (rank == null) continue;
      final lawName = row['law_name']?.toString() ?? '';
      final lawCode = row['law_code']?.toString() ?? '';
      yield TemarioSearchHit(
        kind: TemarioSearchKind.title,
        id: id,
        title: name.isNotEmpty ? name : code,
        subtitle: lawCode.isNotEmpty
            ? (lawName.isNotEmpty ? '$lawCode · $lawName' : lawCode)
            : (lawName.isNotEmpty ? lawName : null),
        rank: rank,
        lawId: row['law_id']?.toString(),
        lawCode: lawCode,
        lawName: lawName,
        titleId: id,
      );
    }
  }

  Iterable<TemarioSearchHit> _hitsFromTests(
    String query,
    List<Map<String, dynamic>> rows,
  ) sync* {
    for (final row in rows) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final name = row['name']?.toString() ?? '';
      final rank = rankSearchFields(query, [name]);
      if (rank == null) continue;
      yield TemarioSearchHit(
        kind: TemarioSearchKind.test,
        id: id,
        title: name.isNotEmpty ? name : id,
        subtitle: _placeLabel(row),
        rank: rank,
        lawId: row['law_id']?.toString(),
        lawCode: row['law_code']?.toString(),
        lawName: row['law_name']?.toString(),
        titleId: row['title_id']?.toString(),
        testId: id,
      );
    }
  }

  Iterable<TemarioSearchHit> _hitsFromQuestions(
    String query,
    List<Map<String, dynamic>> rows,
  ) sync* {
    var count = 0;
    for (final row in rows) {
      if (count >= temarioSearchQuestionLimit) return;
      final testId = row['id']?.toString() ?? '';
      if (testId.isEmpty) continue;
      final payload = row['payload'];
      if (payload is! String || payload.isEmpty) continue;
      TestDefinition def;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map) continue;
        def = TestDefinition.fromApiJson(Map<String, dynamic>.from(decoded));
      } catch (_) {
        continue;
      }
      for (var i = 0; i < def.questions.length; i++) {
        if (count >= temarioSearchQuestionLimit) return;
        final text = def.questions[i].text;
        final rank = rankSearchFields(query, [text]);
        if (rank == null) continue;
        count++;
        yield TemarioSearchHit(
          kind: TemarioSearchKind.question,
          id: '$testId:$i',
          title: text,
          subtitle: def.name.isNotEmpty ? def.name : _placeLabel(row),
          rank: rank,
          lawId: row['law_id']?.toString(),
          lawCode: row['law_code']?.toString(),
          lawName: row['law_name']?.toString(),
          titleId: row['title_id']?.toString(),
          testId: testId,
          questionIndex: i,
        );
      }
    }
  }

  String? _placeLabel(Map<String, dynamic> row) {
    final lawCode = row['law_code']?.toString() ?? '';
    final titleName = row['title_name']?.toString() ?? '';
    if (lawCode.isNotEmpty && titleName.isNotEmpty) return '$lawCode · $titleName';
    if (titleName.isNotEmpty) return titleName;
    if (lawCode.isNotEmpty) return lawCode;
    final lawName = row['law_name']?.toString() ?? '';
    return lawName.isEmpty ? null : lawName;
  }
}
