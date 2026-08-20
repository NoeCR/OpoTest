import 'dart:math';

import '../../../database/app_database.dart';
import '../../../models/local_user.dart';
import '../../../models/question.dart';
import '../../../services/test_scoring.dart';
import '../domain/random_test_mode.dart';

class RandomTestService {
  RandomTestService(this._db);

  final AppDatabase _db;
  final Random _random = Random();

  static const mixedQuestionCount = 15;
  static const refreshMinDays = 7;

  Future<RandomTestPick> pick({
    required RandomTestMode mode,
    required String userId,
  }) async {
    return switch (mode) {
      RandomTestMode.classic => _pickClassic(),
      RandomTestMode.practiced => _pickPracticed(userId),
      RandomTestMode.refresh => _pickRefresh(userId),
      RandomTestMode.mostErrors => _pickMostErrors(userId),
      RandomTestMode.mixed => _pickMixed(),
    };
  }

  Future<RandomTestPick> _pickClassic() async {
    final ids = await _db.getAllTestIds();
    if (ids.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.classic.emptyHint);
    }
    return RandomTestPick.test(ids[_random.nextInt(ids.length)]);
  }

  Future<RandomTestPick> _pickPracticed(String userId) async {
    final attempted = await _db.attemptedTestIds(userId);
    final official = await _db.getAllTestIds();
    final pool = official.where(attempted.contains).toList();
    if (pool.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.practiced.emptyHint);
    }
    return RandomTestPick.test(pool[_random.nextInt(pool.length)]);
  }

  Future<RandomTestPick> _pickRefresh(String userId) async {
    final lastByTest = await _lastAttemptsByTest(userId);
    if (lastByTest.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.refresh.emptyHint);
    }

    final now = DateTime.now();
    final scored = <String, double>{};
    for (final entry in lastByTest.entries) {
      final attempt = entry.value;
      final days = now.difference(attempt.finishedAt).inDays.toDouble();
      final durationBoost = attempt.durationSeconds / 60.0;
      scored[entry.key] = days + durationBoost * 0.15;
    }

    final candidates = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = candidates.take(min(8, candidates.length)).toList();
    final stale = top.where((e) => e.value >= refreshMinDays).toList();
    final pool = stale.isNotEmpty ? stale : top;

    return RandomTestPick.test(_weightedKey(pool.map((e) => MapEntry(e.key, e.value)).toList()));
  }

  Future<RandomTestPick> _pickMostErrors(String userId) async {
    final lastByTest = await _lastAttemptsByTest(userId);
    if (lastByTest.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.mostErrors.emptyHint);
    }

    final weighted = <MapEntry<String, double>>[];
    for (final entry in lastByTest.entries) {
      final test = await _db.getTest(entry.key);
      if (test == null) continue;
      final result = TestScoring.score(
        questions: test.questions,
        answers: entry.value.answers,
        errorFormat: entry.value.errorFormat,
      );
      if (result.incorrect > 0) {
        weighted.add(MapEntry(entry.key, result.incorrect.toDouble()));
      }
    }

    if (weighted.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.mostErrors.emptyHint);
    }

    return RandomTestPick.test(_weightedKey(weighted));
  }

  Future<RandomTestPick> _pickMixed() async {
    final meta = await _db.getOfficialTestsMeta();
    if (meta.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.mixed.emptyHint);
    }

    final shuffled = List.of(meta)..shuffle(_random);
    final selected = <Question>[];
    final usedLaws = <String>{};

    for (final row in shuffled) {
      if (selected.length >= mixedQuestionCount) break;
      final lawId = row.lawId;
      if (lawId.isNotEmpty && usedLaws.contains(lawId) && usedLaws.length >= 3) {
        continue;
      }

      final test = await _db.getTest(row.id);
      if (test == null || test.questions.isEmpty) continue;

      final q = test.questions[_random.nextInt(test.questions.length)];
      selected.add(
        Question(
          order: selected.length + 1,
          text: q.text,
          answers: q.answers,
          solution: q.solution,
          clarificationHtml: q.clarificationHtml,
        ),
      );
      if (lawId.isNotEmpty) usedLaws.add(lawId);
    }

    while (selected.length < mixedQuestionCount && meta.isNotEmpty) {
      final row = meta[_random.nextInt(meta.length)];
      final test = await _db.getTest(row.id);
      if (test == null || test.questions.isEmpty) continue;
      final q = test.questions[_random.nextInt(test.questions.length)];
      selected.add(
        Question(
          order: selected.length + 1,
          text: q.text,
          answers: q.answers,
          solution: q.solution,
          clarificationHtml: q.clarificationHtml,
        ),
      );
    }

    if (selected.isEmpty) {
      return RandomTestPick.empty(RandomTestMode.mixed.emptyHint);
    }

    return RandomTestPick.mixed(
      TestDefinition(
        id: 'mixed_random_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test mixto · ${selected.length} preguntas',
        type: 'mixed',
        questions: selected,
      ),
    );
  }

  Future<Map<String, TestAttempt>> _lastAttemptsByTest(String userId) async {
    final attempts = await _db.attemptsForUserModel(userId);
    final map = <String, TestAttempt>{};
    for (final attempt in attempts) {
      if (attempt.testId.startsWith('mixed_random')) continue;
      map.putIfAbsent(attempt.testId, () => attempt);
    }
    return map;
  }

  String _weightedKey(List<MapEntry<String, double>> weighted) {
    final total = weighted.fold<double>(0, (sum, e) => sum + e.value);
    var roll = _random.nextDouble() * total;
    for (final entry in weighted) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return weighted.last.key;
  }
}
