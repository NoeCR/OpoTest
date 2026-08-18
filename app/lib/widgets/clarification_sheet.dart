import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../theme/app_theme.dart';

class ClarificationSheet extends StatelessWidget {
  const ClarificationSheet({super.key, required this.html});

  final String html;

  static String prepareHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'font-size\s*:\s*[\d.]+px;?', caseSensitive: false), '')
        .replaceAll(RegExp(r'font-family\s*:[^;"]+;?', caseSensitive: false), '');
  }

  static final Map<String, Style> styles = {
    'body': Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(15.5),
      lineHeight: LineHeight.number(1.5),
      color: AppTheme.cardDark,
    ),
    'p': Style(
      margin: Margins.only(bottom: 12),
      fontSize: FontSize(15.5),
    ),
    'span': Style(fontSize: FontSize(15.5)),
    'strong': Style(
      fontWeight: FontWeight.w800,
      backgroundColor: const Color(0xFFFFF2A8),
      color: AppTheme.cardDark,
    ),
    'b': Style(
      fontWeight: FontWeight.w800,
      backgroundColor: const Color(0xFFFFF2A8),
      color: AppTheme.cardDark,
    ),
    'em': Style(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
    'u': Style(textDecoration: TextDecoration.underline),
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(
                'Nota aclaratoria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                child: Html(
                  data: prepareHtml(html),
                  shrinkWrap: true,
                  style: styles,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
