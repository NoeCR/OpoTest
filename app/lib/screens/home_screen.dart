import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../features/custom_tests/presentation/custom_tests_hub_screen.dart';
import '../features/daily_focus/application/daily_focus_service.dart';
import '../features/daily_focus/domain/daily_focus.dart';
import '../features/daily_focus/presentation/daily_focus_card.dart';
import '../features/failed_questions_export/application/failed_questions_export_service.dart';
import '../features/spaced_review/application/spaced_review_service.dart';
import '../features/failed_questions_export/domain/failed_questions_reminder.dart';
import '../features/failed_questions_export/presentation/failed_questions_export_screen.dart';
import '../features/failed_questions_export/presentation/failed_questions_reminder_dialog.dart';
import '../features/in_progress_session/data/in_progress_session_store.dart';
import '../features/in_progress_session/domain/in_progress_session.dart';
import '../features/random_tests/presentation/random_test_hub_screen.dart';
import '../features/random_tests/presentation/random_test_launcher.dart';
import '../features/random_tests/presentation/simulacrum_screen.dart';
import '../features/temario_search/presentation/temario_search_screen.dart';
import '../features/weak_points/presentation/repaso_screen.dart';
import '../navigation/app_navigation.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_decorations.dart';
import '../services/test_launcher.dart';
import 'laws_screen.dart';
import 'settings_screen.dart';
import 'test_history_screen.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int? _questionCount;
  Map<String, dynamic>? _lastAttempt;
  int _markedCount = 0;
  InProgressSession? _inProgress;
  DailyFocusPlan? _dailyFocus;
  var _reminderInFlight = false;

  Future<void> _openSearch() async {
    await context.pushPage(const TemarioSearchScreen());
    if (mounted) await _loadMeta();
  }

  Future<void> _openRandomHub() async {
    if (!context.read<AppState>().contentReady) return;
    await context.pushPage(const RandomTestHubScreen());
    if (mounted) await _loadMeta();
  }

  Future<void> _openSimulacrum() async {
    if (!context.read<AppState>().contentReady) return;
    await context.pushPage(const SimulacrumScreen());
    if (mounted) await _loadMeta();
  }

  Future<void> _runDailyFocus(DailyFocusAction action) async {
    switch (action.kind) {
      case DailyFocusKind.getStarted:
        await context.pushPage(const SettingsScreen());
        break;
      case DailyFocusKind.weakTest:
      case DailyFocusKind.retryLast:
        final testId = action.testId;
        if (testId != null) {
          await TestLauncher.start(context, testId: testId);
        }
        break;
      case DailyFocusKind.markedReview:
      case DailyFocusKind.reinforcement:
      case DailyFocusKind.classic:
        final mode = action.randomMode;
        if (mode != null) {
          await RandomTestLauncher.launchMode(context, mode);
        }
    }
    if (mounted) await _loadMeta();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShowFailedQuestionsReminder();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMeta();
      _maybeShowFailedQuestionsReminder();
    }
  }

  Future<void> _loadMeta() async {
    final db = context.read<AppDatabase>();
    final state = context.read<AppState>();
    final user = state.activeUser;
    if (user == null) return;
    await state.reloadContentFromDatabase();
    final q = await db.countQuestions();
    final last = await db.getLastAttempt(user.id);
    final marked = await db.countMarkedQuestions(user.id);
    if (!mounted) return;
    final inProgress = await context.read<InProgressSessionStore>().getForUser(user.id);
    if (!mounted) return;
    final dailyFocus = await context.read<DailyFocusService>().planFor(
          userId: user.id,
          contentReady: state.contentReady,
        );
    if (mounted) {
      setState(() {
        _questionCount = q;
        _lastAttempt = last;
        _markedCount = marked;
        _inProgress = inProgress;
        _dailyFocus = dailyFocus;
      });
    }
  }

  Future<void> _maybeShowFailedQuestionsReminder() async {
    if (_reminderInFlight || !mounted) return;
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final service = context.read<FailedQuestionsExportService>();

    _reminderInFlight = true;
    try {
      if (!await service.shouldPromptReminder(userId: user.id)) return;
      final interval = await service.reminderInterval();
      final preview = await service.preview(
        userId: user.id,
        range: service.rangeForReminder(interval),
      );
      final dueCount = await SpacedReviewService(context.read<AppDatabase>()).countDue(userId: user.id);
      if (!mounted || preview.items.isEmpty) return;

      final generate = await showFailedQuestionsReminderDialog(
        context,
        interval: interval,
        failCount: preview.items.length,
        dueCount: dueCount,
      );
      if (!mounted) return;
      await service.markReminderPrompted(user.id);
      if (generate) {
        await context.pushPage(
          FailedQuestionsExportScreen(initialPreset: interval.exportPreset),
        );
        if (mounted) await _loadMeta();
      }
    } finally {
      _reminderInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.activeUser!;

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: 'OpoTest',
            subtitle: _questionCount != null
                ? 'Más de $_questionCount preguntas disponibles'
                : 'Cargando temario...',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Buscar',
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width >= 520;
                final SliverGridDelegate gridDelegate;

                if (width < 520) {
                  gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  );
                } else {
                  final extent = width < 900 ? 220.0 : 200.0;
                  gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: extent,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: width >= 900 ? 1.14 : 1.08,
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_inProgress != null) ...[
                          _HomeTile(
                            icon: Icons.play_circle_outline_rounded,
                            iconColor: AppTheme.accentOrange,
                            title: 'Continuar test',
                            subtitle: '${_inProgress!.testName} · ${_inProgress!.progressLabel}',
                            compact: compact,
                            onTap: () => TestLauncher.resume(
                              context,
                              session: _inProgress!,
                            ).then((_) => _loadMeta()),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_dailyFocus != null) ...[
                          DailyFocusCard(
                            plan: _dailyFocus!,
                            compact: compact,
                            onSelect: (action) => _runDailyFocus(action),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _HomeTile(
                          gradient: AppDecorations.headerGradient,
                          icon: Icons.menu_book_rounded,
                          title: 'Nuevo test',
                          subtitle: 'Explorar legislación y temario',
                          compact: compact,
                          onTap: () => context.pushPage(const LawsScreen()).then((_) => _loadMeta()),
                        ),
                        const SizedBox(height: 12),
                        _HomeTile(
                          icon: Icons.edit_note_rounded,
                          iconColor: AppTheme.accentPurple,
                          title: 'Tests propios',
                          subtitle: 'Crear, editar y practicar',
                          compact: compact,
                          onTap: () => context.pushPage(const CustomTestsHubScreen()).then((_) => _loadMeta()),
                        ),
                        const SizedBox(height: 12),
                        GridView(
                          gridDelegate: gridDelegate,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeTile(
                              icon: Icons.shuffle_rounded,
                              iconColor: AppTheme.accentPurple,
                              title: 'Test aleatorio',
                              subtitle: state.contentReady ? 'Elige modo de práctica' : 'Importa temario',
                              enabled: state.contentReady,
                              compact: compact,
                              onTap: state.contentReady ? _openRandomHub : null,
                            ),
                            _HomeTile(
                              icon: Icons.timer_rounded,
                              iconColor: AppTheme.primary,
                              title: 'Simulacro',
                              subtitle: state.contentReady ? 'Examen a tamaño real' : 'Importa temario',
                              enabled: state.contentReady,
                              compact: compact,
                              onTap: state.contentReady ? _openSimulacrum : null,
                            ),
                            _HomeTile(
                              icon: Icons.history_rounded,
                              iconColor: AppTheme.primary,
                              title: 'Historial',
                              subtitle: 'Tests realizados y notas',
                              compact: compact,
                              onTap: () => context.pushPage(const TestHistoryScreen()).then((_) => _loadMeta()),
                            ),
                            _HomeTile(
                              icon: Icons.quiz_outlined,
                              iconColor: AppTheme.accentPurple,
                              title: 'Exportar fallos',
                              subtitle: 'Informe HTML para estudiar',
                              compact: compact,
                              onTap: () => context.pushPage(const FailedQuestionsExportScreen()),
                            ),
                            _HomeTile(
                              icon: Icons.replay_rounded,
                              iconColor: AppTheme.accentOrange,
                              title: 'Reintentar último',
                              subtitle: _lastAttempt != null
                                  ? (_lastAttempt!['test_name'] as String? ?? 'Test').split(' ').take(3).join(' ')
                                  : 'Sin intentos',
                              enabled: _lastAttempt != null,
                              compact: compact,
                              onTap: _lastAttempt == null
                                  ? null
                                  : () => TestLauncher.start(
                                        context,
                                        testId: _lastAttempt!['test_id'] as String,
                                      ),
                            ),
                            _HomeTile(
                              icon: Icons.bookmark_rounded,
                              iconColor: AppTheme.accentOrange,
                              title: 'Revisión',
                              subtitle: _markedCount > 0
                                  ? '$_markedCount preguntas marcadas'
                                  : 'Estudia tus marcas',
                              compact: compact,
                              onTap: () => context.pushPage(const ReviewScreen()).then((_) => _loadMeta()),
                            ),
                            _HomeTile(
                              icon: Icons.insights_rounded,
                              iconColor: Colors.deepOrange.shade400,
                              title: 'Repaso',
                              subtitle: 'Leyes y títulos flojos',
                              compact: compact,
                              onTap: () => context.pushPage(const RepasoScreen()).then((_) => _loadMeta()),
                            ),
                            _HomeTile(
                              icon: Icons.settings_rounded,
                              iconColor: AppTheme.cardDark,
                              title: 'Configuración',
                              subtitle: 'Tests y temario',
                              compact: compact,
                              onTap: () async {
                                await context.pushPage(const SettingsScreen());
                                await _loadMeta();
                                if (mounted) await _maybeShowFailedQuestionsReminder();
                              },
                            ),
                          ],
                        ),
                        if (state.lastImport != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            '${state.laws.length} leyes · ${state.lastImport!.tests} tests importados',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: state.contentReady ? Colors.black45 : Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: state.contentReady ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ] else if (state.laws.isEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.error ??
                                  'Temario no importado. Ve a Configuración e importa el contenido.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
    this.compact = false,
    this.gradient,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool compact;
  final Gradient? gradient;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final onDark = gradient != null;
    final padding = compact ? 12.0 : 14.0;
    final iconBox = compact ? 32.0 : 36.0;
    final iconSize = compact ? 18.0 : 20.0;
    final titleSize = compact ? 14.0 : 15.0;
    final child = Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : (iconColor ?? AppTheme.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: onDark ? Colors.white : (iconColor ?? AppTheme.primary),
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: enabled ? (onDark ? Colors.white : Colors.black87) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: enabled ? (onDark ? Colors.white70 : Colors.black54) : Colors.grey,
            ),
          ),
        ],
      ),
    );

    if (gradient != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: AppDecorations.card(color: enabled ? Colors.white : Colors.grey.shade100),
          child: child,
        ),
      ),
    );
  }
}
