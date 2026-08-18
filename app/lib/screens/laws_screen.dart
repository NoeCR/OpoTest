import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/content_kind.dart';
import '../models/test_stats.dart';
import '../navigation/app_navigation.dart';
import '../services/test_launcher.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/qmap.dart';
import '../widgets/app_decorations.dart';
import '../widgets/content_kind_tabs.dart';
import '../widgets/test_picker_card.dart';
import '../widgets/topic_progress_card.dart';
import 'hierarchy_screen.dart';
import 'title_tests_screen.dart';

class LawsScreen extends StatefulWidget {
  const LawsScreen({super.key});

  @override
  State<LawsScreen> createState() => _LawsScreenState();
}

class _LawsScreenState extends State<LawsScreen> {
  int _reloadToken = 0;

  Future<List<Map<String, dynamic>>> _loadLaws() =>
      context.read<AppDatabase>().getLaws();

  Future<void> _retryImport() async {
    try {
      await context.read<AppState>().importContent();
    } catch (_) {}
    if (mounted) setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(title: 'Legislación', subtitle: 'Selecciona una ley'),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey(_reloadToken),
              future: _loadLaws(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error cargando leyes: ${snap.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                final laws = snap.data ?? [];
                if (laws.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No hay legislación importada.\nEjecuta push-data-android.ps1 y reinicia la app.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _retryImport,
                            child: const Text('Reintentar importación'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: laws.length,
                  itemBuilder: (context, i) {
                    final law = laws[i];
                    final code = law['code'] as String? ?? '';
                    final name = law['name'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.pushPage(
                            LawContentScreen(
                              lawId: law['id'] as String,
                              lawCode: code,
                              lawName: name,
                            ),
                          ),
                          child: Ink(
                            decoration: AppDecorations.card(),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    code.length > 4 ? code.substring(0, 4) : code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.black26),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LawContentScreen extends StatefulWidget {
  const LawContentScreen({
    super.key,
    required this.lawId,
    required this.lawCode,
    required this.lawName,
  });

  final String lawId;
  final String lawCode;
  final String lawName;

  @override
  State<LawContentScreen> createState() => _LawContentScreenState();
}

class _LawContentScreenState extends State<LawContentScreen> {
  ContentKind _kind = ContentKind.tests;
  Set<String> _attempted = {};
  List<Map<String, dynamic>> _titles = [];
  List<String> _examIds = [];
  List<String> _officialIds = [];
  List<String> _ownIds = [];
  Map<String, TestStats> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final userId = context.read<AppState>().activeUser?.id;
    final titles = await db.getTitlesForLaw(widget.lawId);
    final examIds = await db.testIdsForLawType(widget.lawId, ContentKind.exams.dbType);
    final officialIds = await db.testIdsForLawType(widget.lawId, ContentKind.official.dbType);
    final ownIds = await db.testIdsForLawSource(widget.lawId, AppDatabase.testSourceCustom);
    final attempted = userId == null ? <String>{} : await db.attemptedTestIds(userId);
    final stats = userId == null
        ? <String, TestStats>{}
        : await db.statsForTests(userId, [...examIds, ...officialIds, ...ownIds]);
    if (!mounted) return;
    setState(() {
      _titles = titles;
      _examIds = examIds;
      _officialIds = officialIds;
      _ownIds = ownIds;
      _attempted = attempted;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _openTitle(Map<String, dynamic> titleRow) async {
    final db = context.read<AppDatabase>();
    final titleId = titleRow['id'] as String;
    final payload = await db.getTitle(titleId);
    if (!mounted || payload == null) return;

    final title = asStringMap(payload['title']);
    final headerTitle = cleanText(title?['code']).isNotEmpty
        ? cleanText(title?['code'])
        : (titleRow['code'] as String? ?? titleRow['name'] as String? ?? '');
    final headerSubtitle = cleanText(title?['name_es']).isNotEmpty
        ? cleanText(title?['name_es'])
        : cleanText(titleRow['name']);

    final titleTests = titleLevelTestIds(payload, titleId);

    if (titleUsesHierarchy(payload, titleId)) {
      await context.pushPage(
        HierarchyScreen(
          lawId: widget.lawId,
          titleId: titleId,
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle.isNotEmpty ? headerSubtitle : null,
          payload: payload,
        ),
      );
    } else {
      await context.pushPage(
        TitleTestsScreen(
          lawId: widget.lawId,
          titleId: titleId,
          headerTitle: headerTitle,
          headerSubtitle: headerSubtitle.isNotEmpty ? headerSubtitle : null,
          testIds: titleTests,
        ),
      );
    }
    if (mounted) await _load();
  }

  Future<void> _openTest(String testId) async {
    await TestLauncher.start(context, testId: testId);
    if (mounted) await _load();
  }

  ProgressCounts _titleProgress(String titleId, Map<String, dynamic>? extra) {
    return progressCounts(allTestIdsForTitlePayload(extra, titleId), _attempted);
  }

  String _titleFooter(Map<String, dynamic>? extra, String code, String name) {
    final title = asStringMap(extra?['title']);
    final subtitle = cleanText(title?['name_es']);
    if (subtitle.isNotEmpty) return subtitle;
    if (name.isNotEmpty && name != code) return name;
    final chapters = mapsOf(extra?['arChapters']);
    if (chapters.isNotEmpty) return '${chapters.length} capítulos';
    return 'Tests del título';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: widget.lawCode,
            subtitle: widget.lawName,
            gradient: AppDecorations.darkHeaderGradient,
          ),
          ContentKindTabs(
            selected: _kind,
            onSelected: (kind) => setState(() => _kind = kind),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_kind == ContentKind.exams) {
      return TestPickerGrid(
        ids: _examIds,
        stats: _stats,
        onOpen: _openTest,
        emptyLabel: 'No hay exámenes en esta ley',
      );
    }
    if (_kind == ContentKind.official) {
      return TestPickerGrid(
        ids: _officialIds,
        stats: _stats,
        onOpen: _openTest,
        emptyLabel: 'No hay preguntas oficiales en esta ley',
      );
    }
    if (_kind == ContentKind.own) {
      return TestPickerGrid(
        ids: _ownIds,
        stats: _stats,
        onOpen: _openTest,
        emptyLabel: 'No hay preguntas propias en esta ley',
      );
    }

    if (_titles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Importa el temario desde Configuración', textAlign: TextAlign.center),
        ),
      );
    }

    final titlesWithTests = _titles.where((t) {
      Map<String, dynamic>? extra;
      try {
        extra = jsonDecode(t['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
      return titleHasTests(extra, t['id'] as String);
    }).toList();

    if (titlesWithTests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No hay tests en esta ley', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: titlesWithTests.length,
      itemBuilder: (context, i) {
        final t = titlesWithTests[i];
        Map<String, dynamic>? extra;
        try {
          extra = jsonDecode(t['payload'] as String) as Map<String, dynamic>;
        } catch (_) {}
        final code = t['code'] as String? ?? '';
        final name = t['name'] as String? ?? '';
        return TopicProgressCard(
          title: code.isNotEmpty ? code : name,
          footerLabel: _titleFooter(extra, code, name),
          progress: _titleProgress(t['id'] as String, extra),
          onTap: () => _openTitle(t),
        );
      },
    );
  }
}
