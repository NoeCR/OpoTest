import 'package:flutter/material.dart';

/// Inserta etiquetas HTML alrededor de la selección del [controller].
void wrapHtmlSelection(
  TextEditingController controller, {
  required String openTag,
  required String closeTag,
}) {
  final text = controller.text;
  final selection = controller.selection;
  if (!selection.isValid) return;

  if (selection.isCollapsed) {
    final pos = selection.start;
    final insert = '$openTag$closeTag';
    final newText = text.replaceRange(pos, pos, insert);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + openTag.length),
    );
    return;
  }

  final start = selection.start;
  final end = selection.end;
  final selected = text.substring(start, end);
  final wrapped = '$openTag$selected$closeTag';
  final newText = text.replaceRange(start, end, wrapped);
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection(baseOffset: start, extentOffset: start + wrapped.length),
  );
}
