import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/models/local_user.dart';
import 'package:testea_local/services/progress_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressExportService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('opotest_export_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final user = LocalUser(
      id: 'u1',
      name: 'Ana Test',
      createdAt: DateTime.parse('2026-01-01T10:00:00'),
    );

    test('exportUserProgress genera JSON con resumen y by_test', () async {
      final service = ProgressExportService();
      final result = await service.exportUserProgress(
        user: user,
        targetDir: tempDir,
        rawAttempts: [
          {
            'id': 'a1',
            'test_id': '1001',
            'test_name': 'Test 1',
            'finished_at': '2026-08-01T12:00:00.000',
            'duration_seconds': 300,
            'net_score': 8.0,
            'percent_score': 80.0,
            'answers_json': jsonEncode({'0': 1, '1': 2}),
            'exam_simulation': 0,
            'error_format': 100,
          },
          {
            'id': 'a2',
            'test_id': '1001',
            'test_name': 'Test 1',
            'finished_at': '2026-08-02T12:00:00.000',
            'duration_seconds': 280,
            'net_score': 10.0,
            'percent_score': 100.0,
            'answers_json': jsonEncode({'0': 1}),
            'exam_simulation': 1,
            'error_format': 100,
          },
        ],
      );

      expect(result.file.existsSync(), isTrue);
      expect(result.summary['total_attempts'], 2);
      expect(result.summary['unique_tests'], 1);
      expect(result.summary['best_percent'], 100);
      expect(result.summary['average_percent'], 90.0);

      final payload = jsonDecode(await result.file.readAsString()) as Map<String, dynamic>;
      expect(payload['app'], 'testea_local');
      expect(payload['version'], ProgressExportService.exportVersion);
      expect(payload['user']['name'], 'Ana Test');
      expect(payload['by_test'], hasLength(1));

      final byTest = (payload['by_test'] as List).first as Map<String, dynamic>;
      expect(byTest['test_id'], '1001');
      expect(byTest['attempts'], 2);
      expect(byTest['best_percent'], 100);
      expect(byTest['avg_percent'], 90.0);

      final attempts = payload['attempts'] as List;
      final simulated = attempts.cast<Map<String, dynamic>>().firstWhere(
            (a) => a['exam_simulation'] == true,
          );
      expect(simulated['answers'], isA<Map>());
    });

    test('resumen vacío cuando no hay intentos', () async {
      final service = ProgressExportService();
      final result = await service.exportUserProgress(
        user: user,
        targetDir: tempDir,
        rawAttempts: [],
      );

      expect(result.summary['total_attempts'], 0);
      expect(result.summary['average_percent'], isNull);
    });
  });
}
