import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/features/custom_tests/presentation/widgets/html_selection.dart';

void main() {
  group('wrapHtmlSelection', () {
    test('envuelve texto seleccionado en negrita', () {
      final controller = TextEditingController(text: 'Artículo 14 sobre igualdad');
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 10);

      wrapHtmlSelection(controller, openTag: '<strong>', closeTag: '</strong>');

      expect(controller.text, '<strong>Artículo 1</strong>4 sobre igualdad');
    });

    test('inserta etiquetas vacías en el cursor si no hay selección', () {
      final controller = TextEditingController(text: 'Texto ');
      controller.selection = const TextSelection.collapsed(offset: 6);

      wrapHtmlSelection(controller, openTag: '<em>', closeTag: '</em>');

      expect(controller.text, 'Texto <em></em>');
      expect(controller.selection.baseOffset, 10);
    });
  });
}
