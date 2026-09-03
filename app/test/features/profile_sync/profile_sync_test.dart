import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/profile_sync/data/profile_sync_cipher.dart';
import 'package:opotest/features/profile_sync/domain/profile_sync_code.dart';
import 'package:opotest/features/profile_sync/domain/profile_sync_repository.dart';
import 'package:opotest/features/profile_sync/domain/progress_sync_merger.dart';

void main() {
  group('ProfileSyncCode', () {
    test('parsea el código compacto', () {
      const syncId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const token = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      final parsed = ProfileSyncCode.parse('ot1.$syncId.$token');
      expect(parsed.syncId, syncId);
      expect(parsed.token, token);
    });

    test('rechaza un código corto', () {
      expect(() => ProfileSyncCode.parse('ot1.abc'), throwsFormatException);
    });
  });

  group('ProgressSyncMerger', () {
    const merger = ProgressSyncMerger();
    final created = DateTime.parse('2026-01-01T00:00:00Z');

    test('une intentos distintos y remapea al usuario local', () {
      final merged = merger.merge(
        local: {
          'attempts': [
            {'id': 'a1', 'user_id': 'local', 'test_id': 't1', 'percent_score': 80},
          ],
          'marked_questions': [
            {'user_id': 'local', 'test_id': 't1', 'question_index': 0, 'marked_at': '2026-01-02T00:00:00Z'},
          ],
        },
        remote: {
          'attempts': [
            {'id': 'a2', 'user_id': 'cloud', 'test_id': 't2', 'percent_score': 50},
            {'id': 'a1', 'user_id': 'cloud', 'test_id': 't1', 'percent_score': 10},
          ],
          'marked_questions': [
            {'user_id': 'cloud', 'test_id': 't1', 'question_index': 0, 'marked_at': '2026-01-01T00:00:00Z'},
          ],
        },
        userId: 'device-user',
        displayName: 'Noe',
        createdAt: created,
      );

      final attempts = (merged['attempts'] as List).cast<Map>();
      expect(attempts.map((a) => a['id']), containsAll(['a1', 'a2']));
      expect(attempts.every((a) => a['user_id'] == 'device-user'), isTrue);
      final kept = attempts.firstWhere((a) => a['id'] == 'a1');
      expect(kept['percent_score'], 80);

      final marks = (merged['marked_questions'] as List).cast<Map>();
      expect(marks, hasLength(1));
      expect(marks.first['marked_at'], '2026-01-02T00:00:00Z');
      expect(merged['users'].first['id'], 'device-user');
    });

    test('en Leitner se queda la caja más alta', () {
      final merged = merger.merge(
        local: {
          'question_review_states': [
            {'user_id': 'a', 'test_id': 't', 'question_index': 1, 'box': 2, 'next_due': '2026-02-01'},
          ],
        },
        remote: {
          'question_review_states': [
            {'user_id': 'b', 'test_id': 't', 'question_index': 1, 'box': 4, 'next_due': '2026-03-01'},
          ],
        },
        userId: 'u',
        displayName: 'Ana',
        createdAt: created,
      );
      final row = (merged['question_review_states'] as List).first as Map;
      expect(row['box'], 4);
      expect(row['user_id'], 'u');
    });
  });

  group('ProfileSyncCipher', () {
    const cipher = ProfileSyncCipher();

    test('cifra y descifra el mismo mapa', () {
      const syncId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const token = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      final payload = {
        'attempts': [
          {'id': 'a1'},
        ],
      };
      final blob = cipher.seal(syncId: syncId, token: token, payload: payload);
      expect(blob, isNot(contains('a1')));
      expect(cipher.open(syncId: syncId, token: token, blob: blob)['attempts'], payload['attempts']);
    });

    test('un token distinto no abre el blob', () {
      const syncId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final blob = cipher.seal(
        syncId: syncId,
        token: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        payload: const {'ok': true},
      );
      expect(
        () => cipher.open(syncId: syncId, token: 'cccccccccccccccccccccccccccccccc', blob: blob),
        throwsA(isA<ProfileSyncException>()),
      );
    });
  });
}
