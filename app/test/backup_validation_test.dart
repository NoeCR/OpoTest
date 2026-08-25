import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/app_constants.dart';
import 'package:opotest/features/backup/domain/backup_validation.dart';

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

    test('acepta id de backups antiguos', () {
      expect(
        () => validateContentBackup(valid(app: AppConstants.legacyIds.first)),
        returnsNormally,
      );
    });

    test('rechaza app desconocida', () {
      expect(
        () => validateContentBackup(valid(app: 'otra_app')),
        throwsA(isA<BackupValidationException>()),
      );
    });
  });
}
