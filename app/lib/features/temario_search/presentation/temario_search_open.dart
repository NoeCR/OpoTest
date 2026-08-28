import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../database/app_database.dart';
import '../../../navigation/app_navigation.dart';
import '../../../screens/hierarchy_screen.dart';
import '../../../screens/laws_screen.dart';
import '../../../screens/title_tests_screen.dart';
import '../../../services/test_launcher.dart';
import '../../../utils/qmap.dart';
import '../domain/temario_search.dart';

Future<void> openTemarioSearchHit(BuildContext context, TemarioSearchHit hit) {
  switch (hit.kind) {
    case TemarioSearchKind.law:
      return context.pushPage(
        LawContentScreen(
          lawId: hit.lawId ?? hit.id,
          lawCode: hit.lawCode ?? '',
          lawName: hit.lawName ?? hit.title,
        ),
      );
    case TemarioSearchKind.title:
      return _openTitle(context, hit);
    case TemarioSearchKind.test:
    case TemarioSearchKind.question:
      final testId = hit.testId ?? hit.id;
      return TestLauncher.start(context, testId: testId);
  }
}

Future<void> _openTitle(BuildContext context, TemarioSearchHit hit) async {
  final titleId = hit.titleId ?? hit.id;
  final lawId = hit.lawId;
  if (lawId == null || lawId.isEmpty) return;

  final db = context.read<AppDatabase>();
  final payload = await db.getTitle(titleId);
  if (!context.mounted || payload == null) return;

  final title = asStringMap(payload['title']);
  final headerTitle = cleanText(title?['code']).isNotEmpty
      ? cleanText(title?['code'])
      : (hit.title);
  final headerSubtitle = cleanText(title?['name_es']).isNotEmpty
      ? cleanText(title?['name_es'])
      : hit.title;

  final titleTests = titleLevelTestIds(payload, titleId);

  if (titleUsesHierarchy(payload, titleId)) {
    await context.pushPage(
      HierarchyScreen(
        lawId: lawId,
        titleId: titleId,
        headerTitle: headerTitle,
        headerSubtitle: headerSubtitle.isNotEmpty ? headerSubtitle : null,
        payload: payload,
      ),
    );
  } else {
    await context.pushPage(
      TitleTestsScreen(
        lawId: lawId,
        titleId: titleId,
        headerTitle: headerTitle,
        headerSubtitle: headerSubtitle.isNotEmpty ? headerSubtitle : null,
        testIds: titleTests,
      ),
    );
  }
}
