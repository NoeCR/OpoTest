import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Nombre que ve Drive/correo: `OpoTest · Ana_2026/08/25 : 13:05:07`
String backupShareLabel({
  required String profileName,
  DateTime? at,
}) {
  final name = profileName.trim().isEmpty ? 'usuario' : profileName.trim();
  final when = (at ?? DateTime.now()).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${when.year}/${two(when.month)}/${two(when.day)} : ${two(when.hour)}:${two(when.minute)}:${two(when.second)}';
  return 'OpoTest · ${name}_$stamp';
}

String backupExportFileName({
  required String profileName,
  DateTime? at,
}) {
  final label = backupShareLabel(profileName: profileName, at: at);
  return '${label.replaceAll('/', '-').replaceAll(' : ', '_').replaceAll(':', '-')}.json';
}

class BackupFileIo {
  Future<Directory> exportsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!exportsDir.existsSync()) exportsDir.createSync(recursive: true);
    return exportsDir;
  }

  Future<BackupWriteResult> writePayload({
    required String fileName,
    required Map<String, dynamic> payload,
    Directory? targetDir,
  }) async {
    final exportsDir = targetDir ?? await this.exportsDir();
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
