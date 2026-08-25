import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/state/app_state.dart';
import 'package:opotest/state/progress_reload.dart';

import 'helpers/database_helper.dart';

void main() {
  group('AppState.progressGeneration', () {
    late AppDatabase db;
    late AppState state;

    setUp(() async {
      db = await setUpTestDatabase();
      state = AppState(db);
    });

    tearDown(tearDownTestDatabase);

    test('reloadContentFromDatabase habilita el temario tras importar a la base', () async {
      state.error = 'No se encontró el temario en este dispositivo.';
      expect(state.contentReady, isFalse);

      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'CE', 'name_es': 'Constitución', 'order': '1'},
        ],
        'qByLawNew': {'10': {}},
      });
      await db.upsertOfficialTest(sampleTestJson(id: '1001', lawId: '10'));
      await state.reloadContentFromDatabase();

      expect(state.contentReady, isTrue);
      expect(state.error, isNull);
      expect(state.laws, isNotEmpty);
      expect(state.lastImport?.tests, greaterThan(0));
    });

    test('notifyProgressChanged incrementa y notifica', () {
      var notifications = 0;
      state.addListener(() => notifications++);

      expect(state.progressGeneration, 0);
      state.notifyProgressChanged();
      expect(state.progressGeneration, 1);
      expect(notifications, 1);
    });
  });

  group('ProgressReload', () {
    testWidgets('recarga al notificar progreso, no en el primer frame', (tester) async {
      final state = AppState(AppDatabase());
      var reloads = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            home: _ProgressHost(onReload: () => reloads++),
          ),
        ),
      );
      expect(reloads, 0);

      state.notifyProgressChanged();
      await tester.pump();
      expect(reloads, 1);
    });
  });
}

class _ProgressHost extends StatefulWidget {
  const _ProgressHost({required this.onReload});

  final VoidCallback onReload;

  @override
  State<_ProgressHost> createState() => _ProgressHostState();
}

class _ProgressHostState extends State<_ProgressHost> with ProgressReload {
  @override
  void onProgressChanged() => widget.onReload();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
