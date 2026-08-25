import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/content_kind.dart';
import '../models/law_sort_mode.dart';
import '../models/test_stats.dart';
import '../navigation/app_navigation.dart';
import '../services/test_launcher.dart';
import '../state/app_state.dart';
import '../state/progress_reload.dart';
import '../theme/app_theme.dart';
import '../utils/law_sort.dart';
import '../utils/qmap.dart';
import '../widgets/app_decorations.dart';
import '../widgets/content_kind_tabs.dart';
import '../widgets/law_sort_bar.dart';
import '../widgets/test_picker_card.dart';
import '../widgets/topic_progress_card.dart';
import 'hierarchy_screen.dart';
import 'title_tests_screen.dart';

const _lawSortPrefKey = 'laws_sort_mode';

class LawsScreen extends StatefulWidget {
  const LawsScreen({super.key});

  @override
  State<LawsScreen> createState() => _LawsScreenState();
}

class _LawsScreenState extends State<LawsScreen> {
  int _reloadToken = 0;
  LawSortMode _sortMode = LawSortMode.temario;

  @override
  void initState() {
    super.initState();
    _loadSortMode();
  }

  Future<void> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = lawSortModeFromStorage(prefs.getString(_lawSortPrefKey));
    if (mounted) setState(() => _sortMode = mode);
  }

  Future<void> _setSortMode(LawSortMode mode) async {
    setState(() => _sortMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lawSortPrefKey, mode.storageKey);
  }

  Future<_LawsListData> _loadLawsList() async {
    final db = context.read<AppDatabase>();
    final userId = context.read<AppState>().activeUser?.id;
    final laws = await db.getLaws();
    final testsByLaw = await db.allContentIdsGroupedByLaw();
    final attempted = userId == null ? <String>{} : await db.attemptedTestIds(userId);
    final progressByLaw = <String, ProgressCounts>{
      for (final entry in testsByLaw.entries)
        entry.key: progressCounts(entry.value, attempted),
    };
    return _LawsListData(laws: laws, progressByLaw: progressByLaw);
  }

  Future<void> _retryImport() async {
    try {
      await context.read<AppState>().importContent();
    } catch (_) {}
    if (mounted) setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    final progressGeneration = context.select<AppState, int>((s) => s.progressGeneration);
    final userId = context.select<AppState, String?>((s) => s.activeUser?.id);

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(title: 'Legislación', subtitle: 'Selecciona una ley'),
          LawSortBar(
            selected: _sortMode,
            onSelected: _setSortMode,
          ),
          Expanded(
            child: FutureBuilder<_LawsListData>(
              key: ValueKey('$_reloadToken-$progressGeneration-$userId'),
              future: _loadLawsList(),
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
                final laws = snap.data?.laws ?? [];
                final progressByLaw = snap.data?.progressByLaw ?? {};
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
                final lawsWithTests = laws.where((law) {
                  final lawId = law['id'] as String;
                  return (progressByLaw[lawId]?.total ?? 0) > 0;
                }).toList();
                final sortedLaws = sortLaws(lawsWithTests, _sortMode, progressByLaw);

                if (sortedLaws.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay tests en el temario importado', textAlign: TextAlign.center),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: sortedLaws.length,
                  itemBuilder: (context, i) {
                    final law = sortedLaws[i];
                    final lawId = law['id'] as String;
                    final code = law['code'] as String? ?? '';
                    final name = law['name'] as String? ?? '';
                    final subtitle = name.isNotEmpty && name != code ? name : '';
                    return TopicProgressCard(
                      title: code.isNotEmpty ? code : name,
                      footerLabel: subtitle,
                      progress: progressByLaw[lawId] ?? const ProgressCounts(done: 0, total: 0),
                      onTap: () async {
                        await context.pushPage(
                          LawContentScreen(
                            lawId: lawId,
                            lawCode: code,
                            lawName: name,
                          ),
                        );
                        if (mounted) setState(() => _reloadToken++);
                      },
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

class _LawsListData {
  const _LawsListData({required this.laws, required this.progressByLaw});

  final List<Map<String, dynamic>> laws;
  final Map<String, ProgressCounts> progressByLaw;
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

class _LawContentScreenState extends State<LawContentScreen> with ProgressReload {
  ContentKind _kind = ContentKind.tests;
  Set<String> _attempted = {};
  List<Map<String, dynamic>> _titles = [];
  List<String> _examIds = [];
  List<String> _officialIds = [];
  List<String> _ownIds = [];
  List<String> _lawTestIds = [];
  Map<String, TestStats> _stats = {};
  bool _loading = true;
  bool _defaultKindApplied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onProgressChanged() {
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final userId = context.read<AppState>().activeUser?.id;
    final titles = await db.getTitlesForLaw(widget.lawId);
    final lawTestIds = await db.testIdsForLawType(widget.lawId, ContentKind.tests.dbType);
    final examIds = await db.testIdsForLawType(widget.lawId, ContentKind.exams.dbType);
    final officialIds = await db.testIdsForLawType(widget.lawId, ContentKind.official.dbType);
    final ownIds = await db.testIdsForLawSource(widget.lawId, AppDatabase.testSourceCustom);
    final attempted = userId == null ? <String>{} : await db.attemptedTestIds(userId);
    final stats = userId == null
        ? <String, TestStats>{}
        : await db.statsForTests(
            userId,
            [...lawTestIds, ...examIds, ...officialIds, ...ownIds],
          );
    if (!mounted) return;
    setState(() {
      _titles = titles;
      _lawTestIds = lawTestIds;
      _examIds = examIds;
      _officialIds = officialIds;
      _ownIds = ownIds;
      _attempted = attempted;
      _stats = stats;
      if (!_defaultKindApplied &&
          lawTestIds.isEmpty &&
          examIds.isEmpty &&
          officialIds.isEmpty &&
          ownIds.isNotEmpty) {
        _kind = ContentKind.own;
        _defaultKindApplied = true;
      }
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

  int get _testsTabCount {
    if (_lawTestIds.isNotEmpty && _titles.isEmpty) return _lawTestIds.length;
    var total = 0;
    for (final t in _titles) {
      Map<String, dynamic>? extra;
      try {
        extra = jsonDecode(t['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
      if (titleHasTests(extra, t['id'] as String)) {
        total += allTestIdsForTitlePayload(extra, t['id'] as String).length;
      }
    }
    return total;
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
            counts: {
              ContentKind.tests: _testsTabCount,
              ContentKind.exams: _examIds.length,
              ContentKind.official: _officialIds.length,
              ContentKind.own: _ownIds.length,
            },
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

    if (_titles.isEmpty && _lawTestIds.isEmpty) {
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

    if (titlesWithTests.isNotEmpty) {
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

    if (_lawTestIds.isNotEmpty) {
      return TestPickerGrid(
        ids: _lawTestIds,
        stats: _stats,
        onOpen: _openTest,
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No hay tests en esta ley', textAlign: TextAlign.center),
      ),
    );
  }
}
