import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

/// Recarga la pantalla cuando se guarda un intento u otro cambio de progreso,
/// aunque el usuario siga en una ruta encima (p. ej. resultados del test).
mixin ProgressReload<T extends StatefulWidget> on State<T> {
  AppState? _progressState;
  int _seenProgressGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AppState>();
    if (identical(_progressState, next)) return;
    _progressState?.removeListener(_handleProgress);
    _progressState = next;
    _seenProgressGeneration = next.progressGeneration;
    _progressState!.addListener(_handleProgress);
  }

  @override
  void dispose() {
    _progressState?.removeListener(_handleProgress);
    super.dispose();
  }

  void _handleProgress() {
    final gen = _progressState?.progressGeneration ?? 0;
    if (gen == _seenProgressGeneration) return;
    _seenProgressGeneration = gen;
    if (!mounted) return;
    onProgressChanged();
  }

  void onProgressChanged();
}
