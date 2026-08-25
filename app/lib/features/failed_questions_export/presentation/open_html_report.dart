import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

const _androidChannel = MethodChannel('opotest/open_html');

/// Abre un HTML con visor/navegador (ACTION_VIEW + selector), no el menú de compartir.
Future<bool> openHtmlReport(String filePath) async {
  if (Platform.isAndroid) {
    try {
      final opened = await _androidChannel.invokeMethod<bool>('openHtml', {'path': filePath});
      if (opened == true) return true;
    } on PlatformException {
      // Fallback if the native chooser is unavailable.
    } on MissingPluginException {
      // Hot-reload without the Android channel.
    }
  }
  final result = await OpenFilex.open(filePath, type: 'text/html', uti: 'public.html');
  return result.type == ResultType.done;
}
