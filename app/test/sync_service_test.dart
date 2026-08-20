import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:testea_local/database/app_database.dart';
import 'package:testea_local/services/sync_service.dart';

import 'helpers/database_helper.dart';

void main() {
  group('SyncService', () {
    late AppDatabase db;

    setUp(() async {
      db = await setUpTestDatabase();
    });

    tearDown(() async {
      await tearDownTestDatabase();
    });

    test('checkRemoteVersion guarda metadatos en BD', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/testea/get-options/');
        return http.Response(jsonEncode({'ver': '2026.08.1'}), 200);
      });

      final service = SyncService(db);
      final data = await http.runWithClient(
        () => service.checkRemoteVersion(),
        () => client,
      );

      expect(data?['ver'], '2026.08.1');
      expect(await db.getSyncMeta('remote_version'), '2026.08.1');
      expect(await db.getSyncMeta('last_remote_check'), isNotNull);
    });

    test('checkRemoteVersion lanza error en HTTP distinto de 200', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final service = SyncService(db);

      expect(
        () => http.runWithClient(() => service.checkRemoteVersion(), () => client),
        throwsA(isA<StateError>()),
      );
    });

    test('shouldCheckRemote es true sin registro previo', () async {
      final service = SyncService(db);
      expect(await service.shouldCheckRemote(), isTrue);
    });

    test('shouldCheckRemote es false si el último check fue hace poco', () async {
      await db.setSyncMeta('last_remote_check', DateTime.now().toIso8601String());
      final service = SyncService(db);
      expect(await service.shouldCheckRemote(), isFalse);
    });

    test('shouldCheckRemote es true tras intervalDays', () async {
      final old = DateTime.now().subtract(const Duration(days: SyncService.intervalDays));
      await db.setSyncMeta('last_remote_check', old.toIso8601String());
      final service = SyncService(db);
      expect(await service.shouldCheckRemote(), isTrue);
    });
  });
}
