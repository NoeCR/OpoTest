import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/backup/domain/backup_validation.dart';

enum UserErrorContext {
  bootstrap,
  import,
  sync,
  backup,
  general,
}

/// Convierte errores técnicos en mensajes comprensibles para el usuario.
class UserFacingError {
  const UserFacingError._();

  static String message(
    Object error, {
    UserErrorContext context = UserErrorContext.general,
  }) {
    if (error is BackupValidationException) return error.message;

    final raw = _rawMessage(error);
    final mapped = _mapKnownError(raw, error, context);
    if (mapped != null) return mapped;

    if (kDebugMode) {
      debugPrint('UserFacingError sin mapear ($context): $error');
    }
    return _fallback(context);
  }

  static String _rawMessage(Object error) {
    if (error is StateError) return error.message;
    if (error is ArgumentError) return error.message;
    if (error is FormatException) return error.message;
    if (error is TimeoutException) return error.message ?? error.toString();
    if (error is Exception) {
      final text = error.toString();
      final colon = text.indexOf(': ');
      if (colon > 0 && colon < text.length - 2) {
        return text.substring(colon + 2);
      }
    }
    var text = error.toString();
    for (final prefix in ['Bad state: ', 'StateError: ', 'Exception: ', 'Error: ']) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length);
        break;
      }
    }
    return text;
  }

  static String? _mapKnownError(String raw, Object error, UserErrorContext context) {
    final lower = raw.toLowerCase();

    if (lower.contains('temario no encontrado') || lower.contains('no se encuentra la carpeta de datos')) {
      return 'No se encontró el temario en este dispositivo. '
          'Ve a Configuración > Importar temario o vuelve a copiar el contenido tras instalar la app.';
    }

    if (lower.contains('no se importó ningún test')) {
      return 'No se pudieron cargar los tests del temario. '
          'Vuelve a copiar el contenido e importa de nuevo desde Configuración.';
    }

    if (_isNetworkIssue(error, lower)) {
      return switch (context) {
        UserErrorContext.sync => 'No se pudo contactar con el servidor de actualizaciones. '
            'Comprueba tu conexión a internet e inténtalo de nuevo.',
        _ => 'No hay conexión a internet o el servidor no responde. Inténtalo de nuevo.',
      };
    }

    if (error is TimeoutException || lower.contains('timeout') || lower.contains('tiempo de espera')) {
      return switch (context) {
        UserErrorContext.sync => 'La comprobación de actualizaciones tardó demasiado. Inténtalo de nuevo.',
        _ => 'La operación tardó demasiado. Comprueba tu conexión e inténtalo de nuevo.',
      };
    }

    final httpCode = RegExp(r'http\s*(\d{3})', caseSensitive: false).firstMatch(lower)?.group(1);
    if (httpCode != null) {
      final code = int.tryParse(httpCode) ?? 0;
      if (code >= 500) {
        return 'El servidor no está disponible en este momento. Inténtalo más tarde.';
      }
      if (code == 404) {
        return 'No se encontró el servicio de actualizaciones. Inténtalo más tarde.';
      }
      return 'No se pudo completar la solicitud (código $code). Inténtalo de nuevo.';
    }

    if (error is FileSystemException ||
        lower.contains('permission denied') ||
        lower.contains('no such file') ||
        lower.contains('pathnotfoundexception')) {
      return switch (context) {
        UserErrorContext.backup => 'No se pudo acceder al archivo seleccionado. Comprueba permisos e inténtalo de nuevo.',
        UserErrorContext.import => 'No se pudo leer el temario en la ruta indicada. Comprueba que exista e inténtalo de nuevo.',
        _ => 'No se pudo acceder a los archivos necesarios. Inténtalo de nuevo.',
      };
    }

    if (error is FormatException || lower.contains('formatexception') || lower.contains('json')) {
      return switch (context) {
        UserErrorContext.backup => 'El archivo seleccionado no es válido o está dañado.',
        UserErrorContext.import => 'El temario parece estar dañado o incompleto. Vuelve a copiarlo e importa de nuevo.',
        _ => 'Los datos recibidos no son válidos. Inténtalo de nuevo.',
      };
    }

    if (lower.contains('database') || lower.contains('sqlite')) {
      return 'Hubo un problema con los datos locales. Reinicia la app e inténtalo de nuevo.';
    }

    if (_looksUserFriendly(raw)) return raw;
    return null;
  }

  static bool _isNetworkIssue(Object error, String lower) {
    return error is SocketException ||
        error is http.ClientException ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection reset') ||
        lower.contains('connection timed out') ||
        lower.contains('connection closed');
  }

  static bool _looksUserFriendly(String raw) {
    if (raw.length > 220) return false;
    final lower = raw.toLowerCase();
    const technical = [
      'exception',
      'stacktrace',
      'failed host lookup',
      'socketexception',
      'clientexception',
      'os error',
      'http 4',
      'http 5',
      'scripts/',
      'connection closed',
      'uri=http',
      '#0 ',
      'dart:',
      'package:',
    ];
    for (final token in technical) {
      if (lower.contains(token)) return false;
    }
    return true;
  }

  static String _fallback(UserErrorContext context) {
    return switch (context) {
      UserErrorContext.bootstrap => 'No se pudo preparar la aplicación. Reinicia la app e inténtalo de nuevo.',
      UserErrorContext.import => 'No se pudo importar el temario. Inténtalo de nuevo desde Configuración.',
      UserErrorContext.sync => 'No se pudo comprobar actualizaciones. Inténtalo de nuevo más tarde.',
      UserErrorContext.backup => 'No se pudo completar la copia de seguridad. Inténtalo de nuevo.',
      UserErrorContext.general => 'Ha ocurrido un error inesperado. Inténtalo de nuevo.',
    };
  }
}
