/// Almacén remoto del JSON de progreso (Google Drive appData en producción).
abstract class ProgressCloudStore {
  bool get isSignedIn;
  String? get email;

  Future<void> restoreSession();

  Future<void> signIn();

  Future<void> signOut();

  Future<Map<String, dynamic>?> downloadProgress();

  Future<void> uploadProgress(Map<String, dynamic> payload);
}
