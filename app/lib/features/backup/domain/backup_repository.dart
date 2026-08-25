class BackupFileResult {
  const BackupFileResult({
    required this.filePath,
    required this.shareName,
    required this.stats,
  });

  final String filePath;
  final String shareName;
  final Map<String, dynamic> stats;
}

class ContentImportResult {
  const ContentImportResult({
    required this.laws,
    required this.titles,
    required this.testsOfficial,
    required this.testsCustom,
    required this.testsSkipped,
  });

  final int laws;
  final int titles;
  final int testsOfficial;
  final int testsCustom;
  final int testsSkipped;
}

class ProgressImportResult {
  const ProgressImportResult({
    required this.users,
    required this.attempts,
    required this.missingTests,
  });

  final int users;
  final int attempts;
  final int missingTests;
}

abstract class ContentBackupRepository {
  Future<Map<String, dynamic>> buildExportPayload();

  Future<ContentImportResult> importPayload(Map<String, dynamic> payload);
}

abstract class ProgressBackupRepository {
  Future<Map<String, dynamic>> buildExportPayload({String? userId});

  Future<ProgressImportResult> importPayload(
    Map<String, dynamic> payload, {
    bool replaceExistingUsers = false,
  });
}
