import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/users_screen.dart';

class TesteaApp extends StatelessWidget {
  const TesteaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testea Local',
      theme: AppTheme.light(),
      home: const _RootGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(state.importStatus ?? (state.laws.isEmpty ? 'Importando temario local...' : 'Cargando...')),
            ],
          ),
        ),
      );
    }
    if (state.activeUser == null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: const UsersScreen(key: ValueKey('users_gate')),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: MainShell(key: ValueKey('shell_${state.activeUser!.id}')),
    );
  }
}
