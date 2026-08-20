import 'package:flutter/material.dart';

import '../../../../widgets/clarification_sheet.dart';
import 'html_selection.dart';

class ClarificationHtmlEditor extends StatelessWidget {
  const ClarificationHtmlEditor({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  void _wrap(String open, String close) {
    wrapHtmlSelection(controller, openTag: open, closeTag: close);
    onChanged(controller.text);
  }

  Future<void> _preview(BuildContext context) async {
    final html = controller.text.trim();
    if (html.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ClarificationSheet(html: html),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Notas aclaratorias (opcional)',
          style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Negrita — resaltar fragmento',
                  onPressed: () => _wrap('<strong>', '</strong>'),
                  icon: const Icon(Icons.format_bold, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Cursiva',
                  onPressed: () => _wrap('<em>', '</em>'),
                  icon: const Icon(Icons.format_italic, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: controller.text.trim().isEmpty ? null : () => _preview(context),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Vista previa'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Escribe la nota y selecciona texto para marcarlo en negrita o cursiva.',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          minLines: 2,
          maxLines: 5,
          controller: controller,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
