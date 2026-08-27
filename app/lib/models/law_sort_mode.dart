enum LawSortMode {
  temario,
  progressDesc,
  progressAsc,
  leyesFirst,
  decretosFirst,
  nombre,
  custom,
}

extension LawSortModeX on LawSortMode {
  String get label => switch (this) {
        LawSortMode.temario => 'Temario',
        LawSortMode.progressDesc => 'Progreso ↓',
        LawSortMode.progressAsc => 'Progreso ↑',
        LawSortMode.leyesFirst => 'Leyes primero',
        LawSortMode.decretosFirst => 'Decretos primero',
        LawSortMode.nombre => 'Nombre A-Z',
        LawSortMode.custom => 'Personalizado',
      };

  String get storageKey => name;
}

LawSortMode lawSortModeFromStorage(String? value) {
  return LawSortMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => LawSortMode.temario,
  );
}
