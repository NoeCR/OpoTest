import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/test_stats.dart';
import '../services/test_launcher.dart';
import '../state/app_state.dart';
import '../state/progress_reload.dart';
import '../theme/app_theme.dart';
import '../widgets/app_decorations.dart';
import '../widgets/test_picker_card.dart';

class TitleTestsScreen extends StatefulWidget {
  const TitleTestsScreen({
    super.key,
    required this.lawId,
    required this.titleId,
    required this.headerTitle,
    this.headerSubtitle,
    this.chapterId,
    this.testIds,
  });

  final String lawId;
  final String titleId;
  final String headerTitle;
  final String? headerSubtitle;
  final String? chapterId;
  final List<String>? testIds;

  @override
  State<TitleTestsScreen> createState() => _TitleTestsScreenState();
}

class _TitleTestsScreenState extends State<TitleTestsScreen> with ProgressReload {
  List<String> _ids = [];
  Map<String, TestStats> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onProgressChanged() {
    if (_ids.isEmpty) {
      _load();
    } else {
      _reloadStats();
    }
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final userId = context.read<AppState>().activeUser!.id;
    final ids = await _loadTestIds(db);
    final stats = await db.statsForTests(userId, ids);
    if (!mounted) return;
    setState(() {
      _ids = ids;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _reloadStats() async {
    final db = context.read<AppDatabase>();
    final userId = context.read<AppState>().activeUser!.id;
    final stats = await db.statsForTests(userId, _ids);
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<List<String>> _loadTestIds(AppDatabase db) async {
    if (widget.testIds != null) return List<String>.from(widget.testIds!);
    if (widget.chapterId != null) {
      final payload = await db.getChapterPayload(widget.lawId, widget.titleId, widget.chapterId!);
      return db.testIdsForChapter(widget.chapterId!, payload);
    }
    final payload = await db.getTitle(widget.titleId);
    return db.testIdsForTitle(widget.titleId, payload);
  }

  Future<void> _openTest(String testId) async {
    await TestLauncher.start(context, testId: testId);
    if (mounted) await _reloadStats();
  }

  @override
  Widget build(BuildContext context) {
    final done = _ids.where((id) => (_stats[id]?.attempts ?? 0) > 0).length;

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: widget.headerTitle,
            subtitle: widget.headerSubtitle,
            trailing: _ids.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$done/${_ids.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: TestPickerGrid(
                ids: _ids,
                stats: _stats,
                onOpen: _openTest,
              ),
            ),
        ],
      ),
    );
  }
}
