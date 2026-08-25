import '../domain/progress_cloud_store.dart';
import '../domain/progress_sync_exception.dart';

ProgressCloudStore createStore() => UnsupportedProgressCloudStore();

class UnsupportedProgressCloudStore implements ProgressCloudStore {
  @override
  bool get isSignedIn => false;

  @override
  String? get email => null;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> signIn() {
    throw ProgressSyncException(
      'La sincronización con Google Drive no está disponible en esta plataforma.',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Map<String, dynamic>?> downloadProgress() async => null;

  @override
  Future<void> uploadProgress(Map<String, dynamic> payload) async {
    throw ProgressSyncException(
      'La sincronización con Google Drive no está disponible en esta plataforma.',
    );
  }
}
