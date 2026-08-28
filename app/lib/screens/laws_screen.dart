import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/content_kind.dart';
import '../models/law_sort_mode.dart';
import '../models/test_stats.dart';
import '../features/temario_search/presentation/temario_search_screen.dart';
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
const _lawCustomOrderPrefKey = 'laws_custom_order';
const _lawCustomOrderLockedPrefKey = 'laws_custom_order_locked';

class LawsScreen extends StatefulWidget {
  const LawsScreen({super.key});

  @override
  State<LawsScreen> createState() => _LawsScreenState();
}

class _LawsScreenState extends State<LawsScreen> {
  int _reloadToken = 0;
  LawSortMode _sortMode = LawSortMode.temario;
  List<String> _customOrder = [];
  List<String> _displayedLawIds = [];
  bool _customOrderLocked = true;
  Future<_LawsListData>? _lawsFuture;
  String? _lawsFutureKey;
  _LawsListData? _lawsData;

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<void> _loadSortPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = lawSortModeFromStorage(prefs.getString(_lawSortPrefKey));
    final locked = prefs.getBool(_lawCustomOrderLockedPrefKey) ?? true;
    final order = _decodeCustomOrder(prefs.getString(_lawCustomOrderPrefKey));
    if (!mounted) return;
    setState(() {
      _sortMode = mode;
      _customOrderLocked = locked;
      _customOrder = order;
    });
  }

  List<String> _decodeCustomOrder(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistSortMode(LawSortMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lawSortPrefKey, mode.storageKey);
  }

  Future<void> _persistCustomOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lawCustomOrderPrefKey, jsonEncode(order));
  }

  Future<void> _persistCustomLock(bool locked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lawCustomOrderLockedPrefKey, locked);
  }

  Future<void> _setSortMode(LawSortMode mode) async {
    var order = _customOrder;
    if (mode == LawSortMode.custom && order.isEmpty && _displayedLawIds.isNotEmpty) {
      order = List<String>.from(_displayedLawIds);
    }
    setState(() {
      _sortMode = mode;
      _customOrder = order;
    });
    await _persistSortMode(mode);
    if (mode == LawSortMode.custom && order.isNotEmpty) {
      await _persistCustomOrder(order);
    }
  }

  Future<void> _toggleCustomLock() async {
    final next = !_customOrderLocked;
    setState(() => _customOrderLocked = next);
    await _persistCustomLock(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next
              ? 'Orden bloqueado. Ya puedes hacer scroll sin mover secciones.'
              : 'Arrastra las secciones para cambiar el orden.',
        ),
      ),
    );
  }

  void _onReorderLaws(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final ids = List<String>.from(_displayedLawIds);
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final item = ids.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, ids.length);
    ids.insert(insertAt, item);
    setState(() {
      _customOrder = ids;
      _displayedLawIds = ids;
    });
    _persistCustomOrder(ids);
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

  Future<_LawsListData> _lawsFutureFor(String key) {
    if (_lawsFutureKey == key && _lawsFuture != null) return _lawsFuture!;
    _lawsFutureKey = key;
    _lawsFuture = _loadLawsList().then((data) {
      _lawsData = data;
      return data;
    });
    return _lawsFuture!;
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
          GradientHeader(
            title: 'Legislación',
            subtitle: 'Selecciona una ley',
            trailing: IconButton(
              tooltip: 'Buscar',
              onPressed: () => context.pushPage(const TemarioSearchScreen()),
              icon: const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ),
          LawSortBar(
            selected: _sortMode,
            onSelected: _setSortMode,
            customOrderLocked: _customOrderLocked,
            onToggleCustomLock: _toggleCustomLock,
          ),
          Expanded(
            child: FutureBuilder<_LawsListData>(
              future: _lawsFutureFor('$_reloadToken-$progressGeneration-$userId'),
              builder: (context, snap) {
                if (snap.hasError && snap.data == null && _lawsData == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error cargando leyes: ${snap.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                final data = snap.data ?? _lawsData;
                if (data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final laws = data.laws;
                final progressByLaw = data.progressByLaw;
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
                final currentIds = [for (final law in lawsWithTests) law['id'] as String];
                final effectiveCustomOrder = _sortMode == LawSortMode.custom
                    ? mergeCustomLawOrder(_customOrder, currentIds)
                    : _customOrder;
                final sortedLaws = sortLaws(
                  lawsWithTests,
                  _sortMode,
                  progressByLaw,
                  customOrder: effectiveCustomOrder,
                );
                _displayedLawIds = [for (final law in sortedLaws) law['id'] as String];
                if (_sortMode == LawSortMode.custom &&
                    !_listEquals(effectiveCustomOrder, _customOrder)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _customOrder = effectiveCustomOrder);
                    _persistCustomOrder(effectiveCustomOrder);
                  });
                }

                if (sortedLaws.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay tests en el temario importado', textAlign: TextAlign.center),
                    ),
                  );
                }

                final reorderEnabled = _sortMode == LawSortMode.custom && !_customOrderLocked;

                if (reorderEnabled) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: sortedLaws.length,
                    buildDefaultDragHandles: false,
                    onReorder: _onReorderLaws,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          return Material(
                            elevation: 6,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            child: child,
                          );
                        },
                      );
                    },
                    itemBuilder: (context, i) {
                      final law = sortedLaws[i];
                      return ReorderableDragStartListener(
                        key: ValueKey(law['id']),
                        index: i,
                        child: _buildLawCard(
                          law,
                          progressByLaw,
                          trailing: const Icon(
                            Icons.drag_handle_rounded,
                            color: Colors.black38,
                          ),
                        ),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: sortedLaws.length,
                  itemBuilder: (context, i) {
                    return _buildLawCard(sortedLaws[i], progressByLaw);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildLawCard(
    Map<String, dynamic> law,
    Map<String, ProgressCounts> progressByLaw, {
    Widget? trailing,
  }) {
    final lawId = law['id'] as String;
    final code = law['code'] as String? ?? '';
    final name = law['name'] as String? ?? '';
    final subtitle = name.isNotEmpty && name != code ? name : '';
    return TopicProgressCard(
      title: code.isNotEmpty ? code : name,
      footerLabel: subtitle,
      progress: progressByLaw[lawId] ?? const ProgressCounts(done: 0, total: 0),
      trailing: trailing,
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
