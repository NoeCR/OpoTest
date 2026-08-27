import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/in_progress_session/data/in_progress_session_store.dart';
import 'package:opotest/features/in_progress_session/domain/in_progress_session.dart';
import 'package:opotest/models/local_user.dart';
import 'package:opotest/models/question.dart';

import '../../helpers/database_helper.dart';

InProgressSession _session({
  required String userId,
  String testId = '1001',
  Map<int, int> answers = const {0: 1},
  int currentIndex = 1,
}) {
  return InProgressSession.fromLive(
    userId: userId,
    test: TestDefinition.fromApiJson(sampleTestJson(id: testId, questionCount: 4)),
    answers: answers,
    currentIndex: currentIndex,
    elapsedSeconds: 30,
    errorFormat: 100,
    durationMinutes: 0,
    examSimulation: false,
    updatedAt: DateTime.parse('2026-08-27T11:00:00'),
  );
}

void main() {
  group('InProgressSessionStore', () {
    late AppDatabase db;
    late InProgressSessionStore store;
    late LocalUser user;

    setUp(() async {
      db = await setUpTestDatabase();
      store = InProgressSessionStore(db);
      user = LocalUser(
        id: 'user-1',
        name: 'Usuario',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
    });

    tearDown(tearDownTestDatabase);

    test('guarda y recupera una sesión por usuario', () async {
      await store.save(_session(userId: user.id, answers: const {0: 3, 1: 2}));
      final loaded = await store.getForUser(user.id);
      expect(loaded, isNotNull);
      expect(loaded!.testId, '1001');
      expect(loaded.answers, {0: 3, 1: 2});
      expect(loaded.currentIndex, 1);
      expect(loaded.test.questions, hasLength(4));
    });

    test('un usuario solo tiene una sesión: el upsert sustituye', () async {
      await store.save(_session(userId: user.id, testId: '1001', currentIndex: 0));
      await store.save(_session(userId: user.id, testId: '2002', currentIndex: 3));
      final loaded = await store.getForUser(user.id);
      expect(loaded!.testId, '2002');
      expect(loaded.currentIndex, 3);
    });

    test('las sesiones de dos usuarios no se pisan', () async {
      final other = LocalUser(
        id: 'user-2',
        name: 'Otra',
        createdAt: DateTime.parse('2026-01-02T00:00:00'),
      );
      await db.upsertUser(other);
      await store.save(_session(userId: user.id, testId: '1001'));
      await store.save(_session(userId: other.id, testId: '2002'));
      expect((await store.getForUser(user.id))!.testId, '1001');
      expect((await store.getForUser(other.id))!.testId, '2002');
    });

    test('pausar no crea un intento en historial', () async {
      await store.save(_session(userId: user.id));
      expect(await db.attemptsForUser(user.id), isEmpty);
      expect(await db.getLastAttempt(user.id), isNull);
    });

    test('borrar sesión no toca intentos', () async {
      await db.saveAttempt(TestAttempt(
        id: 'att-1',
        userId: user.id,
        testId: '1001',
        testName: 'Demo',
        finishedAt: DateTime.parse('2026-08-27T09:00:00'),
        durationSeconds: 60,
        netScore: 8,
        percentScore: 80,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 100,
      ));
      await store.save(_session(userId: user.id));
      await store.deleteForUser(user.id);
      expect(await store.getForUser(user.id), isNull);
      expect(await db.attemptsForUser(user.id), hasLength(1));
    });

    test('deleteUserData elimina también la sesión a medias', () async {
      await store.save(_session(userId: user.id));
      await db.deleteUserData(user.id);
      expect(await store.getForUser(user.id), isNull);
    });
  });
}
