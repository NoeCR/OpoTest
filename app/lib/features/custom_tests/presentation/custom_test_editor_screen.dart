import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../database/app_database.dart';
import '../../../theme/app_theme.dart';
import '../application/custom_test_service.dart';
import '../domain/custom_law.dart';
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
  List<Map<String, dynamic>> _officialLaws = [];
  List<Map<String, dynamic>> _customLaws = [];
  CustomTestDraft _draft = CustomTestDraft.empty();
  bool _loading = true;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _customLawNameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _customLawNameCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customLawNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final service = context.read<CustomTestService>();
    final laws = await db.getLaws();
    final official = laws.where((l) => !isCustomLawId(l['id'] as String)).toList();
    final custom = laws.where((l) => isCustomLawId(l['id'] as String)).toList();

    CustomTestDraft draft;
    if (widget.testId != null) {
      draft = await service.getDraft(widget.testId!) ?? CustomTestDraft.empty();
      if (isCustomLawId(draft.lawId)) {
        draft = draft.copyWith(customLawName: draft.lawName);
      }
    } else {
      draft = CustomTestDraft.empty(
        lawId: official.isNotEmpty ? official.first['id'] as String : customLawOthersOption,
      );
      if (official.isNotEmpty) {
        final first = official.first;
        draft = draft.copyWith(
          lawCode: first['code']?.toString() ?? '',
          lawName: first['name_es']?.toString() ?? first['name']?.toString() ?? '',
        );
      }
    }

    if (!mounted) return;
    _nameCtrl.text = draft.name;
    _customLawNameCtrl.text = draft.effectiveCustomLawName;
    setState(() {
      _officialLaws = official;
      _customLaws = custom;
      _draft = draft;
      _loading = false;
    });
  }

  String? get _dropdownValue {
    if (isCustomLawOthersOption(_draft.lawId)) return customLawOthersOption;
    if (_draft.lawId.isEmpty) return null;
    if (_officialLaws.any((l) => l['id'] == _draft.lawId) ||
        _customLaws.any((l) => l['id'] == _draft.lawId) ||
        isCustomLawId(_draft.lawId)) {
      return _draft.lawId;
    }
    return null;
  }

  void _setLaw(String? value) {
    if (value == null) return;

    if (value == customLawOthersOption) {
      setState(() {
        _draft = _draft.copyWith(
          lawId: customLawOthersOption,
          lawCode: '',
          lawName: '',
          customLawName: _customLawNameCtrl.text,
        );
      });
      return;
    }

    final law = [..._officialLaws, ..._customLaws].firstWhere(
      (l) => l['id'] == value,
      orElse: () => {},
    );
    final name = law['name_es']?.toString() ?? law['name']?.toString() ?? '';
    final code = law['code']?.toString() ?? '';
    setState(() {
      _draft = _draft.copyWith(
        lawId: value,
        lawCode: code,
        lawName: name,
        customLawName: isCustomLawId(value) ? name : '',
      );
      if (isCustomLawId(value)) {
        _customLawNameCtrl.text = name;
      }
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
      final draft = _draft.copyWith(customLawName: _customLawNameCtrl.text);
      await context.read<CustomTestService>().save(draft);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on CustomTestValidationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<DropdownMenuItem<String>> get _lawDropdownItems {
    final items = <DropdownMenuItem<String>>[
      ..._officialLaws.map(
        (law) => DropdownMenuItem<String>(
          value: law['id'] as String,
          child: Text(_lawDropdownLabel(law), overflow: TextOverflow.ellipsis, maxLines: 2),
        ),
      ),
      ..._customLaws.map(
        (law) => DropdownMenuItem<String>(
          value: law['id'] as String,
          child: Text(_lawDropdownLabel(law), overflow: TextOverflow.ellipsis, maxLines: 2),
        ),
      ),
      const DropdownMenuItem<String>(
        value: customLawOthersOption,
        child: Text('Otros — nueva sección'),
      ),
    ];
    return items;
  }

  List<Widget> get _selectedLawLabels {
    return [
      ..._officialLaws.map((law) => _selectedLawLabel(law)),
      ..._customLaws.map((law) => _selectedLawLabel(law)),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Otros — nueva sección',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ];
  }

  Widget _selectedLawLabel(Map<String, dynamic> law) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _lawDropdownLabel(law),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCustomLawName = _draft.usesCustomLawSection;

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
                          value: _dropdownValue,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Ley o sección',
                            border: OutlineInputBorder(),
                          ),
                          selectedItemBuilder: (context) => _selectedLawLabels,
                          items: _lawDropdownItems,
                          onChanged: _setLaw,
                        ),
                        if (showCustomLawName) ...[
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la sección',
                              hintText: 'Ej. Psicotécnicos, Inglés técnico...',
                              border: OutlineInputBorder(),
                            ),
                            controller: _customLawNameCtrl,
                            onChanged: (v) => setState(
                              () => _draft = _draft.copyWith(customLawName: v, lawName: v),
                            ),
                          ),
                        ],
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
    if (isCustomLawId(law['id'] as String)) {
      return law['name']?.toString() ?? law['code']?.toString() ?? 'Sección propia';
    }
    final code = law['code']?.toString() ?? '';
    final name = law['name_es']?.toString() ?? law['name']?.toString() ?? '';
    if (code.isNotEmpty && name.isNotEmpty) return '$code — $name';
    return code.isNotEmpty ? code : name;
  }
}
