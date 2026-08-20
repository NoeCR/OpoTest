import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../database/app_database.dart';
import '../../../navigation/app_navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../application/custom_test_service.dart';
import '../domain/custom_test_draft.dart';
import 'custom_test_editor_screen.dart';

class CustomTestsHubScreen extends StatefulWidget {
  const CustomTestsHubScreen({super.key});

  @override
  State<CustomTestsHubScreen> createState() => _CustomTestsHubScreenState();
}

class _CustomTestsHubScreenState extends State<CustomTestsHubScreen> {
  List<CustomTestSummary> _tests = [];
  List<Map<String, dynamic>> _laws = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final service = context.read<CustomTestService>();
    final laws = await db.getLaws();
    final tests = await service.listSummaries();
    if (!mounted) return;
    setState(() {
      _laws = laws;
      _tests = tests;
      _loading = false;
    });
  }

  String _lawLabel(String lawId) {
    for (final law in _laws) {
      if (law['id'] == lawId) {
        final code = law['code']?.toString() ?? '';
        final name = law['name_es']?.toString() ?? law['name']?.toString() ?? '';
        if (code.isNotEmpty && name.isNotEmpty) return '$code — $name';
        return code.isNotEmpty ? code : name;
      }
    }
    return lawId;
  }

  Future<void> _createTest() async {
    final changed = await context.pushPage(const CustomTestEditorScreen());
    if (changed == true && mounted) await _load();
  }

  Future<void> _editTest(CustomTestSummary summary) async {
    final changed = await context.pushPage(CustomTestEditorScreen(testId: summary.id));
    if (changed == true && mounted) await _load();
  }

  Future<void> _deleteTest(CustomTestSummary summary) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar test'),
        content: Text('¿Eliminar "${summary.name}"? Se borrarán también sus intentos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await context.read<CustomTestService>().delete(summary.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test eliminado')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: const Text('Tests propios'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTest,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo test'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 64, color: Colors.black.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes tests propios',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea preguntas manuales y aparecerán en la pestaña «Preguntas propias» de cada ley.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = _tests[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _editTest(t),
                        child: Ink(
                          decoration: AppDecorations.card(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_lawLabel(t.lawId)} · ${t.questionCount} preguntas',
                                        style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _deleteTest(t),
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
