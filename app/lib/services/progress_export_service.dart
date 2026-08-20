import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/local_user.dart';

class ProgressExportResult {
  const ProgressExportResult({required this.file, required this.summary});

  final File file;
  final Map<String, dynamic> summary;
}

class ProgressExportService {
  static const exportVersion = 1;

  Future<ProgressExportResult> exportUserProgress({
    required LocalUser user,
    required List<Map<String, dynamic>> rawAttempts,
    Directory? targetDir,
  }) async {
    final attempts = rawAttempts.map(_normalizeAttempt).toList();
    final summary = _buildSummary(attempts);
    final byTest = _buildByTest(attempts);

    final payload = {
      'app': 'testea_local',
      'version': exportVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'user': {
        'id': user.id,
        'name': user.name,
        'created_at': user.createdAt.toIso8601String(),
      },
      'summary': summary,
      'by_test': byTest,
      'attempts': attempts,
    };

    final exportsDir = targetDir ?? await _defaultExportsDir();

    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final safeName = user.name.replaceAll(RegExp(r'[^\w\-]+'), '_').toLowerCase();
    final fileName = 'testea_${safeName}_$stamp.json';
    final file = File(p.join(exportsDir.path, fileName));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

    return ProgressExportResult(file: file, summary: summary);
  }

  Future<Directory> _defaultExportsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!exportsDir.existsSync()) exportsDir.createSync(recursive: true);
    return exportsDir;
  }

  Map<String, dynamic> _normalizeAttempt(Map<String, dynamic> row) {
    Map<String, dynamic> answers = {};
    try {
      final raw = jsonDecode(row['answers_json'] as String? ?? '{}') as Map<String, dynamic>;
      answers = raw.map((k, v) => MapEntry(k, v));
    } catch (_) {}

    return {
      'id': row['id'],
      'test_id': row['test_id'],
      'test_name': row['test_name'],
      'finished_at': row['finished_at'],
      'duration_seconds': row['duration_seconds'],
      'net_score': row['net_score'],
      'percent_score': row['percent_score'],
      'exam_simulation': (row['exam_simulation'] as num?) == 1,
      'error_format': row['error_format'],
      'answers': answers,
    };
  }

  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> attempts) {
    if (attempts.isEmpty) {
      return {
        'total_attempts': 0,
        'unique_tests': 0,
        'average_percent': null,
        'best_percent': null,
        'last_attempt_at': null,
      };
    }

    final percents = attempts.map((a) => (a['percent_score'] as num?)?.toDouble() ?? 0).toList();
    final tests = attempts.map((a) => a['test_id']).toSet();
    return {
      'total_attempts': attempts.length,
      'unique_tests': tests.length,
      'average_percent': double.parse((percents.reduce((a, b) => a + b) / percents.length).toStringAsFixed(1)),
      'best_percent': percents.reduce((a, b) => a > b ? a : b).round(),
      'last_attempt_at': attempts.first['finished_at'],
    };
  }

  List<Map<String, dynamic>> _buildByTest(List<Map<String, dynamic>> attempts) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final a in attempts) {
      grouped.putIfAbsent(a['test_id'] as String, () => []).add(a);
    }

    final rows = grouped.entries.map((e) {
      final list = e.value;
      final percents = list.map((a) => (a['percent_score'] as num?)?.toDouble() ?? 0).toList();
      final avg = percents.reduce((a, b) => a + b) / percents.length;
      final best = percents.reduce((a, b) => a > b ? a : b);
      list.sort((a, b) => (b['finished_at'] as String).compareTo(a['finished_at'] as String));
      return {
        'test_id': e.key,
        'test_name': list.first['test_name'],
        'attempts': list.length,
        'avg_percent': double.parse(avg.toStringAsFixed(1)),
        'best_percent': best.round(),
        'last_finished_at': list.first['finished_at'],
      };
    }).toList();

    rows.sort((a, b) => (b['last_finished_at'] as String).compareTo(a['last_finished_at'] as String));
    return rows;
  }
}
