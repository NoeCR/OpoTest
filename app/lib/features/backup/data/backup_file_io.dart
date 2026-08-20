import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupFileIo {
  Future<Directory> exportsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!exportsDir.existsSync()) exportsDir.createSync(recursive: true);
    return exportsDir;
  }

  Future<BackupWriteResult> writePayload({
    required String prefix,
    required Map<String, dynamic> payload,
    Directory? targetDir,
  }) async {
    final exportsDir = targetDir ?? await this.exportsDir();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = '${prefix}_$stamp.json';
    final file = File(p.join(exportsDir.path, fileName));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return BackupWriteResult(file: file, filePath: file.path);
  }

  Future<Map<String, dynamic>> pickAndReadJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw BackupFileCancelledException();
    }
    final file = result.files.first;
    final text = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }
}

class BackupWriteResult {
  const BackupWriteResult({required this.file, required this.filePath});

  final File file;
  final String filePath;
}

class BackupFileCancelledException implements Exception {
  @override
  String toString() => 'Selección cancelada.';
}
