import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../app_constants.dart';
import '../database/app_database.dart';
import '../models/local_user.dart';
import '../services/content_importer.dart';
import '../utils/user_facing_error.dart';

class AppState extends ChangeNotifier {
  AppState(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  LocalUser? activeUser;
  bool loading = true;
  String? error;
  ImportResult? lastImport;
  List<Map<String, dynamic>> laws = [];
  String? importStatus;

  bool get contentReady => laws.isNotEmpty && (lastImport?.tests ?? 0) > 0;

  Future<void> bootstrap() async {
    loading = true;
    importStatus = 'Comprobando temario...';
    error = null;
    notifyListeners();
    try {
      final users = await _db.getUsers();
      final activeId = await _db.activeUserId();
      if (activeId != null) {
        for (final u in users) {
          if (u.id == activeId) {
            activeUser = u;
            break;
          }
        }
      }

      await _refreshContentStats();
      await _ensureContentImported();
    } catch (e, st) {
      error = UserFacingError.message(e, context: UserErrorContext.bootstrap);
      debugPrint('Bootstrap error: $e\n$st');
    } finally {
      await _refreshContentStats();
      _validateContentState();
      importStatus = null;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureContentImported() async {
    String? dataPath;
    try {
      dataPath = await ContentImporter.resolveDataPath();
    } catch (e) {
      error = UserFacingError.message(e, context: UserErrorContext.import);
      return;
    }

    final expected = await ContentImporter.readExpectedStats(dataPath);
    var lawCount = laws.length;
    var testCount = lastImport?.tests ?? 0;

    if (lawCount < expected.laws) {
      importStatus = 'Importando legislación y temario...';
      notifyListeners();
      await importContent(dataPath);
      lawCount = laws.length;
      testCount = lastImport?.tests ?? 0;
    }

    if (testCount < expected.tests) {
      importStatus = 'Importando tests ($lawCount leyes · objetivo ${expected.tests})...';
      notifyListeners();
      await importTestsOnly(dataPath);
      testCount = lastImport?.tests ?? 0;

      if (testCount == 0) {
        importStatus = 'Reintentando importación completa...';
        notifyListeners();
        await importContent(dataPath);
        testCount = lastImport?.tests ?? 0;
      }
    }

    // Los JSON de artículos llegaron a pisar títulos (sin capítulos). Se reimportan siempre: es rápido.
    importStatus = 'Actualizando estructura del temario...';
    notifyListeners();
    await ContentImporter(_db).importTitlesFromDirectory(dataPath);
    await _refreshContentStats();
  }

  void _validateContentState() {
    final tests = lastImport?.tests ?? 0;
    if (laws.isEmpty) {
      error ??= 'Temario no importado. En Android ejecuta scripts/push-data-android.ps1 '
          '(después de instalar el APK en release) y reinicia la app.';
      return;
    }
    if (tests == 0) {
      error = 'Las leyes están cargadas pero los tests no. Ve a Configuración > Importar temario '
          '(o reinicia la app tras ejecutar push-data-android.ps1).';
    }
  }

  Future<void> _refreshContentStats() async {
    laws = await _db.getLaws();
    final tests = await _db.countTests();
    final titles = await _db.countTitles();
    if (laws.isNotEmpty || tests > 0 || titles > 0) {
      lastImport = ImportResult(laws: laws.length, titles: titles, tests: tests);
    }
  }

  Future<ImportResult> importContent([String? path]) async {
    error = null;
    try {
      final importer = ContentImporter(_db);
      final dataPath = path ?? await ContentImporter.resolveDataPath();
      debugPrint('${AppConstants.name} import from: $dataPath');
      lastImport = await importer.importFromDirectory(dataPath);
      debugPrint('${AppConstants.name} import done: ${lastImport!.laws} laws, ${lastImport!.tests} tests');
      if (lastImport!.tests == 0) {
        final onDisk = await ContentImporter.countJsonTests(dataPath);
        if (onDisk > 0) {
          throw StateError(
            'No se importó ningún test ($onDisk en disco). '
            'Reinstala la app con flutter run para aplicar la última versión.',
          );
        }
      }
    } catch (e, st) {
      error = UserFacingError.message(e, context: UserErrorContext.import);
      debugPrint('Import error: $e\n$st');
      rethrow;
    } finally {
      await _refreshContentStats();
      _validateContentState();
      notifyListeners();
    }
    return lastImport!;
  }

  Future<ImportResult> importTestsOnly([String? path]) async {
    error = null;
    try {
      final importer = ContentImporter(_db);
      final dataPath = path ?? await ContentImporter.resolveDataPath();
      debugPrint('${AppConstants.name} test-only import from: $dataPath');
      final tests = await importer.importTestsOnly(dataPath);
      lastImport = ImportResult(
        laws: laws.length,
        titles: await _db.countTitles(),
        tests: tests,
      );
      debugPrint('${AppConstants.name} test-only import done: $tests tests');
    } catch (e, st) {
      error = UserFacingError.message(e, context: UserErrorContext.import);
      debugPrint('Test-only import error: $e\n$st');
      rethrow;
    } finally {
      await _refreshContentStats();
      _validateContentState();
      notifyListeners();
    }
    return lastImport!;
  }

  Future<void> createUser(String name) async {
    final user = LocalUser(id: _uuid.v4(), name: name.trim(), createdAt: DateTime.now());
    await _db.upsertUser(user);
    await selectUser(user);
  }

  Future<void> selectUser(LocalUser user) async {
    activeUser = user;
    await _db.setActiveUserId(user.id);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> attemptsForUser(String userId) =>
      _db.attemptsForUser(userId);

  Future<void> deleteUser(LocalUser user) async {
    await _db.deleteUserData(user.id);
    if (activeUser?.id == user.id) {
      activeUser = null;
      await _db.setActiveUserId(null);
    }
    notifyListeners();
  }
}
