import '../../../app_constants.dart';
import '../../backup/domain/backup_constants.dart';

/// Fusiona dos copias de progreso del mismo perfil (unión por id, sin pisar usuarios locales).
class ProgressSyncMerger {
  const ProgressSyncMerger();

  Map<String, dynamic> merge({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    required String userId,
    required String displayName,
    required DateTime createdAt,
  }) {
    final localN = remapToUser(local, userId: userId, displayName: displayName, createdAt: createdAt);
    final remoteN = remapToUser(remote, userId: userId, displayName: displayName, createdAt: createdAt);

    return {
      'app': localN['app'] ?? remoteN['app'] ?? AppConstants.id,
      'kind': localN['kind'] ?? remoteN['kind'] ?? progressBackupKind,
      'version': localN['version'] ?? remoteN['version'] ?? progressBackupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'users': [
        {
          'id': userId,
          'name': displayName,
          'created_at': createdAt.toIso8601String(),
        },
      ],
      'attempts': _mergeById(_asMaps(localN['attempts']), _asMaps(remoteN['attempts'])),
      'marked_questions': _mergeMarked(_asMaps(localN['marked_questions']), _asMaps(remoteN['marked_questions'])),
      'recovered_questions':
          _mergeRecovered(_asMaps(localN['recovered_questions']), _asMaps(remoteN['recovered_questions'])),
      'question_review_states':
          _mergeReviews(_asMaps(localN['question_review_states']), _asMaps(remoteN['question_review_states'])),
    };
  }

  Map<String, dynamic> remapToUser(
    Map<String, dynamic> payload, {
    required String userId,
    required String displayName,
    required DateTime createdAt,
  }) {
    Map<String, dynamic> row(Map<String, dynamic> raw) {
      final copy = Map<String, dynamic>.from(raw);
      copy['user_id'] = userId;
      return copy;
    }

    return {
      ...payload,
      'users': [
        {
          'id': userId,
          'name': displayName,
          'created_at': createdAt.toIso8601String(),
        },
      ],
      'attempts': _asMaps(payload['attempts']).map(row).toList(),
      'marked_questions': _asMaps(payload['marked_questions']).map(row).toList(),
      'recovered_questions': _asMaps(payload['recovered_questions']).map(row).toList(),
      'question_review_states': _asMaps(payload['question_review_states']).map(row).toList(),
    };
  }

  List<Map<String, dynamic>> _asMaps(Object? raw) {
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  List<Map<String, dynamic>> _mergeById(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final row in [...a, ...b]) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId.putIfAbsent(id, () => row);
    }
    return byId.values.toList();
  }

  String _markKey(Map<String, dynamic> row) =>
      '${row['test_id']}:${row['question_index']}';

  List<Map<String, dynamic>> _mergeMarked(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final byKey = <String, Map<String, dynamic>>{};
    for (final row in [...a, ...b]) {
      final key = _markKey(row);
      final current = byKey[key];
      if (current == null) {
        byKey[key] = row;
        continue;
      }
      final at = DateTime.tryParse(row['marked_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final currentAt =
          DateTime.tryParse(current['marked_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (at.isAfter(currentAt)) byKey[key] = row;
    }
    return byKey.values.toList();
  }

  List<Map<String, dynamic>> _mergeRecovered(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final byKey = <String, Map<String, dynamic>>{};
    for (final row in [...a, ...b]) {
      final key = _markKey(row);
      final current = byKey[key];
      if (current == null) {
        byKey[key] = row;
        continue;
      }
      final at = DateTime.tryParse(row['recovered_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final currentAt =
          DateTime.tryParse(current['recovered_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (at.isAfter(currentAt)) byKey[key] = row;
    }
    return byKey.values.toList();
  }

  List<Map<String, dynamic>> _mergeReviews(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final byKey = <String, Map<String, dynamic>>{};
    for (final row in [...a, ...b]) {
      final key = _markKey(row);
      final current = byKey[key];
      if (current == null) {
        byKey[key] = row;
        continue;
      }
      final box = (row['box'] as num?)?.toInt() ?? 0;
      final currentBox = (current['box'] as num?)?.toInt() ?? 0;
      if (box > currentBox) {
        byKey[key] = row;
        continue;
      }
      if (box < currentBox) continue;
      final due = DateTime.tryParse(row['next_due']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final currentDue =
          DateTime.tryParse(current['next_due']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (due.isAfter(currentDue)) byKey[key] = row;
    }
    return byKey.values.toList();
  }
}
