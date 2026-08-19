import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../navigation/app_navigation.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_decorations.dart';
import '../services/test_launcher.dart';
import 'laws_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int? _questionCount;
  Map<String, dynamic>? _lastAttempt;

  Future<void> _startRandomTest() async {
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<AppDatabase>();
    final tests = await db.getAllTestIds();
    if (tests.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No hay tests importados. Importa el temario en Configuración.')),
      );
      return;
    }

    final pick = Random().nextInt(tests.length);
    final testId = tests[pick];

    if (!mounted) return;
    await TestLauncher.start(context, testId: testId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMeta();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadMeta();
  }

  Future<void> _loadMeta() async {
    final db = context.read<AppDatabase>();
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final q = await db.countQuestions();
    final last = await db.getLastAttempt(user.id);
    if (mounted) setState(() { _questionCount = q; _lastAttempt = last; });
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
            trailing: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
                        _HomeTile(
                          gradient: AppDecorations.headerGradient,
                          icon: Icons.menu_book_rounded,
                          title: 'Nuevo test',
                          subtitle: 'Explorar legislación y temario',
                          compact: compact,
                          onTap: () => context.pushPage(const LawsScreen()).then((_) => _loadMeta()),
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
                              subtitle: state.contentReady ? 'Empieza al azar' : 'Importa temario',
                              enabled: state.contentReady,
                              compact: compact,
                              onTap: state.contentReady ? _startRandomTest : null,
                            ),
                            _HomeTile(
                              icon: Icons.bar_chart_rounded,
                              iconColor: AppTheme.primary,
                              title: 'Estadísticas',
                              subtitle: 'Historial de intentos',
                              compact: compact,
                              onTap: () => context.pushPage(const StatisticsScreen()).then((_) => _loadMeta()),
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
                              icon: Icons.settings_rounded,
                              iconColor: AppTheme.cardDark,
                              title: 'Configuración',
                              subtitle: 'Tests y temario',
                              compact: compact,
                              onTap: () async {
                                await context.pushPage(const SettingsScreen());
                                _loadMeta();
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
                                  'Temario no importado. En Android ejecuta scripts/push-data-android.ps1 y reinicia la app.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ),
                        ],
                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Text(state.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
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
