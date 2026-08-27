import '../../../database/app_database.dart';
import '../domain/in_progress_session.dart';

class InProgressSessionStore {
  InProgressSessionStore(this._db);

  final AppDatabase _db;

  Future<InProgressSession?> getForUser(String userId) {
    return _db.getInProgressSession(userId);
  }

  Future<void> save(InProgressSession session) {
    return _db.upsertInProgressSession(session);
  }

  Future<void> deleteForUser(String userId) {
    return _db.deleteInProgressSession(userId);
  }
}
