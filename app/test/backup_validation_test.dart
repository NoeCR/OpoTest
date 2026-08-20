import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/app_constants.dart';
import 'package:testea_local/features/backup/domain/backup_validation.dart';

void main() {
  group('validateContentBackup', () {
    Map<String, dynamic> valid({String app = AppConstants.id}) => {
          'app': app,
          'kind': 'content_backup',
          'version': 1,
          'tests': [],
        };

    test('acepta id opotest', () {
      expect(() => validateContentBackup(valid()), returnsNormally);
    });

    test('acepta id legacy testea_local', () {
      expect(() => validateContentBackup(valid(app: 'testea_local')), returnsNormally);
    });

    test('rechaza app desconocida', () {
      expect(
        () => validateContentBackup(valid(app: 'otra_app')),
        throwsA(isA<BackupValidationException>()),
      );
    });
  });
}
