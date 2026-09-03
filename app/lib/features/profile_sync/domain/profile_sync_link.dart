class ProfileSyncLink {
  const ProfileSyncLink({
    required this.userId,
    required this.syncId,
    required this.token,
    this.lastSyncedAt,
    this.lastError,
  });

  final String userId;
  final String syncId;
  final String token;
  final DateTime? lastSyncedAt;
  final String? lastError;

  bool get hasSynced => lastSyncedAt != null;

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'sync_id': syncId,
        'token': token,
        'last_synced_at': lastSyncedAt?.toIso8601String(),
        'last_error': lastError,
      };

  factory ProfileSyncLink.fromMap(Map<String, dynamic> map) => ProfileSyncLink(
        userId: map['user_id'] as String,
        syncId: map['sync_id'] as String,
        token: map['token'] as String,
        lastSyncedAt: DateTime.tryParse(map['last_synced_at'] as String? ?? ''),
        lastError: map['last_error'] as String?,
      );
}

class ProfileSyncSnapshot {
  const ProfileSyncSnapshot({
    required this.updatedAt,
    required this.payload,
  });

  final DateTime updatedAt;
  final Map<String, dynamic> payload;
}

class ProfileSyncResult {
  const ProfileSyncResult({
    required this.status,
    this.message,
  });

  final ProfileSyncStatus status;
  final String? message;

  static const skipped = ProfileSyncResult(status: ProfileSyncStatus.skipped);
  static const disabled = ProfileSyncResult(status: ProfileSyncStatus.disabled);
}

enum ProfileSyncStatus { synced, skipped, disabled, error }
