import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../navigation/app_navigation.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/qmap.dart';
import '../widgets/app_decorations.dart';
import '../widgets/topic_progress_card.dart';
import 'title_tests_screen.dart';

/// Lista de capítulos, secciones y tests de artículo (p. ej. art. 10 en Título I).
class HierarchyScreen extends StatefulWidget {
  const HierarchyScreen({
    super.key,
    required this.lawId,
    required this.titleId,
    required this.headerTitle,
    this.headerSubtitle,
    required this.payload,
    this.chapterId,
  });

  final String lawId;
  final String titleId;
  final String headerTitle;
  final String? headerSubtitle;
  final Map<String, dynamic> payload;
  final String? chapterId;

  @override
  State<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends State<HierarchyScreen> {
  Set<String> _attempted = {};

  bool get _isChapter => widget.chapterId != null;

  List<Map<String, dynamic>> get _folders {
    final raw = _isChapter ? widget.payload['arSections'] : widget.payload['arChapters'];
    final list = mapsOf(raw);
    list.sort((a, b) => (int.tryParse(a['order']?.toString() ?? '0') ?? 0)
        .compareTo(int.tryParse(b['order']?.toString() ?? '0') ?? 0));
    return list.where((folder) => _folderTestIds(folder).isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final userId = context.read<AppState>().activeUser?.id;
    if (userId == null) return;
    final attempted = await context.read<AppDatabase>().attemptedTestIds(userId);
    if (!mounted) return;
    setState(() => _attempted = attempted);
  }

  String _folderLabel(Map<String, dynamic> folder) {
    final code = cleanText(folder['code']);
    final name = cleanText(folder['name_es']);
    if (code.isNotEmpty) return code;
    return name;
  }

  String? _folderSubtitle(Map<String, dynamic> folder) {
    final name = cleanText(folder['name_es']);
    final code = cleanText(folder['code']);
    if (name.isNotEmpty && name != code) return name;
    return null;
  }

  Future<void> _openChapter(Map<String, dynamic> chapter) async {
    final db = context.read<AppDatabase>();
    final id = chapter['id']?.toString() ?? '';
    final chapterPayload = await db.getChapterPayload(widget.lawId, widget.titleId, id) ??
        {
          'qByChapter': widget.payload['qByChapter'],
          'arArticles': const [],
          'arSections': const [],
        };
    if (!mounted) return;

    final headerTitle = _folderLabel(chapter);
    final headerSubtitle = _folderSubtitle(chapter);
    final chapterTests = allTestIdsFromQMap(chapterPayload['qByChapter'], id);

    if (chapterUsesHierarchy(chapterPayload, id)) {
      await context.pushPage(
        HierarchyScreen(
          lawId: widget.lawId,
          titleId: widget.titleId,
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle,
          payload: chapterPayload,
          chapterId: id,
        ),
      );
    } else if (chapterTests.isNotEmpty) {
      await context.pushPage(
        TitleTestsScreen(
          lawId: widget.lawId,
          titleId: widget.titleId,
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle,
          testIds: chapterTests,
        ),
      );
    }
    if (mounted) await _loadProgress();
  }

  Future<void> _openSection(Map<String, dynamic> section) async {
    final id = section['id']?.toString() ?? '';
    final ids = allTestIdsFromQMap(widget.payload['qBySection'], id);
    if (ids.isEmpty) return;
    await context.pushPage(
      TitleTestsScreen(
        lawId: widget.lawId,
        titleId: widget.titleId,
        headerTitle: _folderLabel(section),
        headerSubtitle: _folderSubtitle(section),
        chapterId: widget.chapterId,
        testIds: ids,
      ),
    );
    if (mounted) await _loadProgress();
  }

  Future<void> _openArticle(ArticleTestGroup article) async {
    await context.pushPage(
      TitleTestsScreen(
        lawId: widget.lawId,
        titleId: widget.titleId,
        headerTitle: article.code,
        chapterId: widget.chapterId,
        testIds: article.testIds,
      ),
    );
    if (mounted) await _loadProgress();
  }

  List<String> _folderTestIds(Map<String, dynamic> folder) {
    final id = folder['id']?.toString() ?? '';
    if (_isChapter) {
      return allTestIdsFromQMap(widget.payload['qBySection'], id);
    }
    return allTestIdsFromQMap(widget.payload['qByChapter'], id);
  }

  String _folderFooter(Map<String, dynamic> folder) {
    final subtitle = _folderSubtitle(folder);
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    final text = cleanText(folder['text_es']);
    if (text.isNotEmpty) return text;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final articles = articleTestGroups(widget.payload);
    final folders = _folders;

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: widget.headerTitle,
            subtitle: widget.headerSubtitle,
            gradient: AppDecorations.darkHeaderGradient,
          ),
          Expanded(
            child: folders.isEmpty && articles.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay tests en este bloque', textAlign: TextAlign.center),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      for (final article in articles)
                        TopicProgressCard(
                          title: article.code,
                          footerLabel: '',
                          progress: progressCounts(article.testIds, _attempted),
                          onTap: () => _openArticle(article),
                        ),
                      for (final folder in folders)
                        TopicProgressCard(
                          title: _folderLabel(folder),
                          footerLabel: _folderFooter(folder),
                          progress: progressCounts(_folderTestIds(folder), _attempted),
                          onTap: () => _isChapter ? _openSection(folder) : _openChapter(folder),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
