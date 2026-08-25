import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Abre el menú nativo para enviar un JSON (Drive, correo, Bluetooth, etc.).
///
/// Drive y el correo usan [shareName] como título del archivo, no el de la app.
Future<ShareResultStatus> shareBackupFile(
  BuildContext context, {
  required String filePath,
  required String shareName,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  Rect? origin;
  if (box != null && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  final fileName = shareName.replaceAll('/', '-').replaceAll(' : ', '_').replaceAll(':', '-');
  final withExt = fileName.toLowerCase().endsWith('.json') ? fileName : '$fileName.json';
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(filePath, mimeType: 'application/json', name: withExt)],
      subject: shareName,
      title: shareName,
      fileNameOverrides: [withExt],
      sharePositionOrigin: origin,
    ),
  );
  return result.status;
}
