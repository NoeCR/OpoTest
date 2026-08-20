import 'package:flutter/material.dart';

import '../../domain/custom_question_draft.dart';
import 'clarification_html_editor.dart';

class CustomQuestionEditorCard extends StatefulWidget {
  const CustomQuestionEditorCard({
    super.key,
    required this.index,
    required this.question,
    required this.onChanged,
    required this.onRemove,
    this.canRemove = true,
  });

  final int index;
  final CustomQuestionDraft question;
  final ValueChanged<CustomQuestionDraft> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<CustomQuestionEditorCard> createState() => _CustomQuestionEditorCardState();
}

class _CustomQuestionEditorCardState extends State<CustomQuestionEditorCard> {
  late TextEditingController _textCtrl;
  late List<TextEditingController> _answerCtrls;
  late TextEditingController _clarificationCtrl;

  @override
  void initState() {
    super.initState();
    _bindControllers(widget.question);
  }

  @override
  void didUpdateWidget(CustomQuestionEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _syncControllers(widget.question);
    }
  }

  void _bindControllers(CustomQuestionDraft q) {
    _textCtrl = TextEditingController(text: q.text);
    _answerCtrls = List.generate(4, (i) => TextEditingController(text: q.answers[i]));
    _clarificationCtrl = TextEditingController(text: q.clarificationHtml);
  }

  void _syncControllers(CustomQuestionDraft q) {
    if (_textCtrl.text != q.text) _textCtrl.text = q.text;
    for (var i = 0; i < 4; i++) {
      if (_answerCtrls[i].text != q.answers[i]) _answerCtrls[i].text = q.answers[i];
    }
    if (_clarificationCtrl.text != q.clarificationHtml) {
      _clarificationCtrl.text = q.clarificationHtml;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    for (final c in _answerCtrls) {
      c.dispose();
    }
    _clarificationCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.question.copyWith(
        text: _textCtrl.text,
        answers: _answerCtrls.map((c) => c.text).toList(),
        clarificationHtml: _clarificationCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Pregunta ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Eliminar pregunta',
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enunciado',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 6,
              controller: _textCtrl,
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i++) ...[
              TextField(
                decoration: InputDecoration(
                  labelText: 'Respuesta ${i + 1}',
                  border: const OutlineInputBorder(),
                ),
                controller: _answerCtrls[i],
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Text('Respuesta correcta', style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {widget.question.solution},
              onSelectionChanged: (s) {
                widget.onChanged(widget.question.copyWith(solution: s.first));
              },
            ),
            const SizedBox(height: 12),
            ClarificationHtmlEditor(
              controller: _clarificationCtrl,
              onChanged: (_) => _emit(),
            ),
          ],
        ),
      ),
    );
  }
}
