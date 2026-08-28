import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/weak_points/application/weak_points_service.dart';
import 'package:opotest/features/weak_points/domain/weak_points.dart';
import 'package:opotest/models/local_user.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('WeakPointsService', () {
    late AppDatabase db;
    late WeakPointsService service;
    late LocalUser user;
    final now = DateTime(2026, 8, 28, 12);

    setUp(() async {
      db = await setUpTestDatabase();
      service = WeakPointsService(db);
      user = LocalUser(
        id: 'user-1',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'CE', 'name_es': 'Constitución', 'order': '1'},
          {'id': '11', 'code': 'EBEP', 'name_es': 'Estatuto Básico', 'order': '2'},
        ],
        'qByLawNew': {'10': {}, '11': {}},
      });
      await db.importTitle('10', {
        'title': {'id': '82', 'code': 'T1', 'name_es': 'Derechos', 'order': '1'},
      });
      await db.importTitle('11', {
        'title': {'id': '90', 'code': 'T4', 'name_es': 'Excedencia', 'order': '1'},
      });
      await db.upsertOfficialTest(sampleTestJson(id: '1001', lawId: '10', titleId: '82'));
      await db.upsertOfficialTest(
        sampleTestJson(id: '1002', name: 'Test EBEP', lawId: '11', titleId: '90'),
      );
    });

    tearDown(tearDownTestDatabase);

    Future<void> saveAttempt({
      required String id,
      required String testId,
      required DateTime finishedAt,
      required double percent,
    }) {
      return db.saveAttempt(TestAttempt(
        id: id,
        userId: user.id,
        testId: testId,
        testName: testId,
        finishedAt: finishedAt,
        durationSeconds: 60,
        netScore: 5,
        percentScore: percent,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 100,
      ));
    }

    test('el JOIN excluye sintéticos y ordena lo flojo primero', () async {
      await saveAttempt(
        id: 'att-ce',
        testId: '1001',
        finishedAt: now.subtract(const Duration(hours: 2)),
        percent: 80,
      );
      await saveAttempt(
        id: 'att-ebep',
        testId: '1002',
        finishedAt: now.subtract(const Duration(hours: 1)),
        percent: 35,
      );
      await saveAttempt(
        id: 'att-mix',
        testId: 'mixed_random_1',
        finishedAt: now,
        percent: 5,
      );

      final topics = await service.topicsFor(
        userId: user.id,
        scope: WeakPointsScope.laws,
      );
      expect(topics.map((t) => t.id), ['11', '10']);
      expect(topics.first.stats.lastPercent, 35);
      expect(topics.every((t) => t.id != 'mixed_random_1'), isTrue);
    });

    test('agrega títulos con media y último porcentaje', () async {
      await saveAttempt(id: 'a1', testId: '1001', finishedAt: now.subtract(const Duration(hours: 1)), percent: 70);
      await saveAttempt(id: 'a2', testId: '1002', finishedAt: now, percent: 40);

      final topics = await service.topicsFor(
        userId: user.id,
        scope: WeakPointsScope.titles,
      );
      expect(topics.first.id, '90');
      expect(topics.first.stats.lastPercent, 40);
      expect(topics.last.stats.lastPercent, 70);
    });
  });
}
