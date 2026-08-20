import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../database/app_database.dart';

class SyncService {
  SyncService(this._db);

  final AppDatabase _db;
  static const baseUrl = 'https://glados-cakeserver.com/';
  static const intervalDays = 7;
  static const _requestTimeout = Duration(seconds: 20);

  Future<Map<String, dynamic>?> checkRemoteVersion() async {
    final http.Response res;
    try {
      res = await http
          .get(
            Uri.parse('${baseUrl}api/testea/get-options/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_requestTimeout);
    } on SocketException catch (e) {
      throw StateError(
        'Sin conexión al servidor (${e.message}). '
        'Comprueba WiFi/datos móviles e inténtalo de nuevo.',
      );
    } on TimeoutException {
      throw StateError(
        'Tiempo de espera agotado al contactar $baseUrl. '
        'Comprueba tu conexión e inténtalo de nuevo.',
      );
    }
    if (res.statusCode != 200) {
      throw StateError('HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _db.setSyncMeta('last_remote_check', DateTime.now().toIso8601String());
    await _db.setSyncMeta('remote_version', data['ver']?.toString() ?? '');
    return data;
  }

  Future<bool> shouldCheckRemote() async {
    final last = await _db.getSyncMeta('last_remote_check');
    if (last == null) return true;
    final dt = DateTime.tryParse(last);
    if (dt == null) return true;
    return DateTime.now().difference(dt).inDays >= intervalDays;
  }
}
