import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opotest/features/backup/domain/backup_validation.dart';
import 'package:opotest/utils/user_facing_error.dart';

void main() {
  group('UserFacingError', () {
    test('preserva mensajes ya legibles de sync', () {
      const msg = 'Sin conexión al servidor. Comprueba WiFi/datos móviles e inténtalo de nuevo.';
      expect(
        UserFacingError.message(StateError(msg), context: UserErrorContext.sync),
        msg,
      );
    });

    test('mapea SocketException en sync', () {
      final text = UserFacingError.message(
        const SocketException('Failed host lookup: glados-cakeserver.com'),
        context: UserErrorContext.sync,
      );
      expect(text, contains('servidor de actualizaciones'));
      expect(text, isNot(contains('SocketException')));
    });

    test('mapea ClientException', () {
      final text = UserFacingError.message(
        http.ClientException('Connection closed', Uri.parse('https://example.com')),
        context: UserErrorContext.sync,
      );
      expect(text, contains('conexión'));
      expect(text, isNot(contains('ClientException')));
    });

    test('mapea TimeoutException', () {
      final text = UserFacingError.message(
        TimeoutException('timeout'),
        context: UserErrorContext.sync,
      );
      expect(text, contains('tardó demasiado'));
    });

    test('mapea HTTP 500', () {
      final text = UserFacingError.message(
        StateError('HTTP 500'),
        context: UserErrorContext.sync,
      );
      expect(text, contains('servidor no está disponible'));
    });

    test('mapea temario no encontrado', () {
      final text = UserFacingError.message(
        StateError('Temario no encontrado. En Android/iOS: ejecuta scripts/push-data-android.ps1'),
        context: UserErrorContext.import,
      );
      expect(text, contains('No se encontró el temario'));
      expect(text, isNot(contains('push-data-android')));
    });

    test('usa mensaje de BackupValidationException', () {
      final text = UserFacingError.message(
        BackupValidationException('Archivo no válido para OpoTest.'),
        context: UserErrorContext.backup,
      );
      expect(text, 'Archivo no válido para OpoTest.');
    });

    test('fallback genérico oculta detalle técnico', () {
      final text = UserFacingError.message(
        Exception('SqliteException(11): database disk image is malformed'),
        context: UserErrorContext.bootstrap,
      );
      expect(text, contains('datos locales'));
      expect(text, isNot(contains('SqliteException')));
    });
  });
}
