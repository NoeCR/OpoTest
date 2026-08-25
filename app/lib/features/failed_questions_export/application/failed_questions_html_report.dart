import 'dart:convert';

import '../domain/failed_question_item.dart';
import '../domain/failed_questions_range.dart';

class FailedQuestionsHtmlReport {
  const FailedQuestionsHtmlReport();

  String build({
    required String userName,
    required FailedQuestionsRange range,
    required List<FailedQuestionItem> items,
    required int skippedMissingTests,
    DateTime? generatedAt,
  }) {
    final at = (generatedAt ?? DateTime.now()).toLocal();
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="es">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1">')
      ..writeln('<title>${_esc('OpoTest · Preguntas falladas · $userName · ${_fileStamp(at)}')}</title>')
      ..writeln('<style>')
      ..writeln(_css)
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<header>')
      ..writeln('<p class="brand">OpoTest</p>')
      ..writeln('<h1>Preguntas falladas</h1>')
      ..writeln('<p class="meta">${_esc(userName)} · ${_esc(range.label)}</p>')
      ..writeln('<p class="meta">Generado el ${_esc(_stamp(at))} · ${items.length} pregunta${items.length == 1 ? '' : 's'}</p>');
    if (skippedMissingTests > 0) {
      buffer.writeln(
        '<p class="warn">${_esc('Se omitieron $skippedMissingTests intento(s) de tests que ya no están en el temario.')}</p>',
      );
    }
    buffer.writeln('</header>');

    if (items.isEmpty) {
      buffer.writeln('<p>No hay preguntas falladas en este periodo.</p>');
    } else {
      for (var i = 0; i < items.length; i++) {
        _writeItem(buffer, items[i], i + 1);
      }
    }

    buffer
      ..writeln('</body>')
      ..writeln('</html>');
    return buffer.toString();
  }

  void _writeItem(StringBuffer buffer, FailedQuestionItem item, int number) {
    final q = item.question;
    buffer
      ..writeln('<article>')
      ..writeln('<h2>${_esc('$number. ${q.text}')}</h2>')
      ..writeln('<p class="ref">${_esc(item.lawLabel)}'
          '${item.titleName != null && item.titleName!.isNotEmpty ? ' · ${_esc(item.titleName!)}' : ''}'
          ' · ${_esc(item.testName)}</p>')
      ..writeln('<p class="when">Fallada el ${_esc(_stamp(item.failedAt.toLocal()))}</p>')
      ..writeln('<ol class="options">');
    for (var i = 0; i < q.answers.length; i++) {
      final option = i + 1;
      final letter = String.fromCharCode(64 + option);
      final classes = <String>[];
      if (option == item.correctAnswer) classes.add('correct');
      if (option == item.userAnswer) classes.add('yours');
      buffer.writeln(
        '<li class="${classes.join(' ')}"><span class="letter">$letter</span> ${_esc(q.answers[i])}</li>',
      );
    }
    buffer
      ..writeln('</ol>')
      ..writeln('<p><strong>Tu respuesta:</strong> ${_esc(_optionLabel(item.userAnswer, q.answers))}</p>')
      ..writeln('<p><strong>Correcta:</strong> ${_esc(_optionLabel(item.correctAnswer, q.answers))}</p>');
    if (q.clarificationHtml.trim().isNotEmpty) {
      buffer
        ..writeln('<div class="note">')
        ..writeln('<h3>Nota aclaratoria</h3>')
        ..writeln(q.clarificationHtml)
        ..writeln('</div>');
    }
    buffer.writeln('</article>');
  }

  String _optionLabel(int option, List<String> answers) {
    if (option < 1 || option > answers.length) return '—';
    final letter = String.fromCharCode(64 + option);
    return '$letter. ${answers[option - 1]}';
  }

  String _stamp(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
  }

  /// Fecha en el título: Chrome/Android la usan al imprimir o guardar como PDF.
  String _fileStamp(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)}_${two(at.hour)}-${two(at.minute)}';
  }

  String _esc(String value) => const HtmlEscape(HtmlEscapeMode.element).convert(value);

  static const _css = '''
body { font-family: Georgia, "Times New Roman", serif; max-width: 720px; margin: 24px auto; padding: 0 16px 48px; color: #222; line-height: 1.45; }
.brand { letter-spacing: 0.12em; text-transform: uppercase; color: #F4524C; font-weight: 700; font-size: 12px; }
h1 { margin: 0 0 8px; font-size: 28px; }
.meta, .ref, .when { color: #555; font-size: 14px; }
.warn { background: #fff4f3; border-left: 3px solid #F4524C; padding: 8px 12px; }
article { border-top: 1px solid #eee; padding: 20px 0; }
h2 { font-size: 18px; margin: 0 0 8px; }
.options { list-style: none; padding: 0; }
.options li { margin: 6px 0; padding: 8px 10px; border-radius: 8px; background: #f6f7f9; }
.options li.correct { background: #e7f6ea; }
.options li.yours:not(.correct) { background: #fdecea; }
.letter { display: inline-block; width: 1.4em; font-weight: 700; }
.note { background: #f8f5ff; padding: 12px; border-radius: 8px; margin-top: 12px; }
.note h3 { margin: 0 0 8px; font-size: 14px; }
''';
}
