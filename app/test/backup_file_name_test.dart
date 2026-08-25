import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/backup/data/backup_file_io.dart';

void main() {
  test('backupShareLabel usa perfil y fecha yyyy/MM/dd : HH:mm:ss', () {
    final label = backupShareLabel(
      profileName: 'Ana',
      at: DateTime(2026, 8, 25, 12, 53, 7),
    );
    expect(label, 'OpoTest · Ana_2026/08/25 : 12:53:07');
  });

  test('backupExportFileName evita barras y dos puntos en el archivo', () {
    final name = backupExportFileName(
      profileName: 'Ana',
      at: DateTime(2026, 8, 25, 12, 53, 7),
    );
    expect(name, 'OpoTest · Ana_2026-08-25_12-53-07.json');
  });

  test('backupShareLabel de contenido usa la misma fecha', () {
    final label = backupShareLabel(
      profileName: 'contenido',
      at: DateTime(2026, 8, 25, 9, 0, 0),
    );
    expect(label, 'OpoTest · contenido_2026/08/25 : 09:00:00');
  });
}
