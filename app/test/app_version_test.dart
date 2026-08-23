import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/utils/app_version.dart';

void main() {
  group('formatAppVersionLabel', () {
    test('incluye versión y número de build', () {
      expect(
        formatAppVersionLabel(version: '1.7.1', buildNumber: '19'),
        'Versión 1.7.1 (19)',
      );
    });

    test('omite el build si viene vacío', () {
      expect(
        formatAppVersionLabel(version: '1.7.1', buildNumber: '  '),
        'Versión 1.7.1',
      );
    });

    test('indica versión desconocida si falta el número', () {
      expect(
        formatAppVersionLabel(version: '', buildNumber: '19'),
        'Versión desconocida',
      );
    });
  });
}
