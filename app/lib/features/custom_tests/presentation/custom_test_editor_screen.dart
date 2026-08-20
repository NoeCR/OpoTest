import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../database/app_database.dart';
import '../../../theme/app_theme.dart';
import '../application/custom_test_service.dart';
import '../domain/custom_question_draft.dart';
import '../domain/custom_test_draft.dart';
import '../domain/custom_test_validation.dart';
import 'widgets/custom_question_editor_card.dart';

class CustomTestEditorScreen extends StatefulWidget {
  const CustomTestEditorScreen({super.key, this.testId});

  final String? testId;

  @override
  State<CustomTestEditorScreen> createState() => _CustomTestEditorScreenState();
}

class _CustomTestEditorScreenState extends State<CustomTestEditorScreen> {
  List<Map<String, dynamic>> _laws = [];
  CustomTestDraft _draft = CustomTestDraft.empty();
  bool _loading = true;
  bool _saving = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final service = context.read<CustomTestService>();
    final laws = await db.getLaws();

    CustomTestDraft draft;
    if (widget.testId != null) {
      draft = await service.getDraft(widget.testId!) ?? CustomTestDraft.empty();
    } else {
      draft = CustomTestDraft.empty(
        lawId: laws.isNotEmpty ? laws.first['id'] as String : '',
      );
      if (laws.isNotEmpty) {
        draft = draft.copyWith(
          lawCode: laws.first['code']?.toString() ?? '',
          lawName: laws.first['name_es']?.toString() ?? laws.first['name']?.toString() ?? '',
        );
      }
    }

    if (!mounted) return;
    _nameCtrl.text = draft.name;
    setState(() {
      _laws = laws;
      _draft = draft;
      _loading = false;
    });
  }

  void _setLaw(String? lawId) {
    if (lawId == null) return;
    final law = _laws.firstWhere((l) => l['id'] == lawId, orElse: () => {});
    setState(() {
      _draft = _draft.copyWith(
        lawId: lawId,
        lawCode: law['code']?.toString() ?? '',
        lawName: law['name_es']?.toString() ?? law['name']?.toString() ?? '',
      );
    });
  }

  void _updateQuestion(int index, CustomQuestionDraft q) {
    final questions = List<CustomQuestionDraft>.from(_draft.questions);
    questions[index] = q;
    setState(() => _draft = _draft.copyWith(questions: questions));
  }

  void _addQuestion() {
    if (_draft.questions.length >= 100) return;
    setState(() {
      _draft = _draft.copyWith(
        questions: [..._draft.questions, CustomQuestionDraft.empty()],
      );
    });
  }

  void _removeQuestion(int index) {
    if (_draft.questions.length <= 1) return;
    final questions = List<CustomQuestionDraft>.from(_draft.questions)..removeAt(index);
    setState(() => _draft = _draft.copyWith(questions: questions));
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() => _saving = true);
      await context.read<CustomTestService>().save(_draft);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on CustomTestValidationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: Text(widget.testId == null ? 'Nuevo test propio' : 'Editar test'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _draft.lawId.isEmpty ? null : _draft.lawId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Ley',
                            border: OutlineInputBorder(),
                          ),
                          selectedItemBuilder: (context) => _laws
                              .map(
                                (law) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _lawDropdownLabel(law),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                          items: _laws
                              .map(
                                (law) => DropdownMenuItem<String>(
                                  value: law['id'] as String,
                                  child: Text(
                                    _lawDropdownLabel(law),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _setLaw,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Nombre del test',
                            border: OutlineInputBorder(),
                          ),
                          controller: _nameCtrl,
                          onChanged: (v) => setState(() => _draft = _draft.copyWith(name: v)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _draft.questions.length; i++)
                  CustomQuestionEditorCard(
                    key: ValueKey('q-$i-${widget.testId ?? 'new'}'),
                    index: i,
                    question: _draft.questions[i],
                    canRemove: _draft.questions.length > 1,
                    onChanged: (q) => _updateQuestion(i, q),
                    onRemove: () => _removeQuestion(i),
                  ),
                if (_draft.questions.length < 100)
                  OutlinedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir pregunta'),
                  ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  String _lawDropdownLabel(Map<String, dynamic> law) {
    final code = law['code']?.toString() ?? '';
    final name = law['name_es']?.toString() ?? law['name']?.toString() ?? '';
    if (code.isNotEmpty && name.isNotEmpty) return '$code — $name';
    return code.isNotEmpty ? code : name;
  }
}
