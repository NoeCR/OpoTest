import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Abre el menú nativo para enviar un archivo (Drive, correo, Bluetooth, etc.).
///
/// Drive y el correo usan [shareName] como título del archivo, no el de la app.
Future<ShareResultStatus> shareBackupFile(
  BuildContext context, {
  required String filePath,
  required String shareName,
  String mimeType = 'application/json',
  String fileExtension = '.json',
}) async {
  final box = context.findRenderObject() as RenderBox?;
  Rect? origin;
  if (box != null && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  final sanitized = shareName.replaceAll('/', '-').replaceAll(' : ', '_').replaceAll(':', '-');
  final ext = fileExtension.startsWith('.') ? fileExtension : '.$fileExtension';
  final withExt = sanitized.toLowerCase().endsWith(ext.toLowerCase()) ? sanitized : '$sanitized$ext';
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(filePath, mimeType: mimeType, name: withExt)],
      subject: shareName,
      title: shareName,
      fileNameOverrides: [withExt],
      sharePositionOrigin: origin,
    ),
  );
  return result.status;
}
