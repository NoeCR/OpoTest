enum RandomTestMode {
  classic,
  own,
  practiced,
  refresh,
  mostErrors,
  mixed,
  reinforcement,
  markedReview,
}

extension RandomTestModeLabels on RandomTestMode {
  String get title => switch (this) {
        RandomTestMode.classic => 'Al azar',
        RandomTestMode.own => 'Tests propios',
        RandomTestMode.practiced => 'Temario practicado',
        RandomTestMode.refresh => 'Refrescar olvidados',
        RandomTestMode.mostErrors => 'Más fallos recientes',
        RandomTestMode.mixed => 'Mixto multisección',
        RandomTestMode.reinforcement => 'Test de refuerzo',
        RandomTestMode.markedReview => 'Test de repaso',
      };

  String get subtitle => switch (this) {
        RandomTestMode.classic => 'Cualquier test del temario importado',
        RandomTestMode.own => 'Solo tests que has creado tú',
        RandomTestMode.practiced => 'Solo tests que ya has completado',
        RandomTestMode.refresh => 'Tests sin repetir hace tiempo o muy largos',
        RandomTestMode.mostErrors => 'Prioriza donde más fallaste la última vez',
        RandomTestMode.mixed => 'Preguntas aleatorias de varias leyes',
        RandomTestMode.reinforcement => 'Fallos que toca repasar hoy',
        RandomTestMode.markedReview => 'Preguntas que marcaste para revisión',
      };

  String get emptyHint => switch (this) {
        RandomTestMode.classic => 'Importa el temario para practicar.',
        RandomTestMode.own => 'Crea al menos un test propio para usar este modo.',
        RandomTestMode.practiced => 'Completa al menos un test para usar este modo.',
        RandomTestMode.refresh => 'Necesitas intentos previos para detectar tests olvidados.',
        RandomTestMode.mostErrors => 'Completa tests con fallos para usar este modo.',
        RandomTestMode.mixed => 'Importa el temario para generar un mix.',
        RandomTestMode.reinforcement => 'No hay preguntas pendientes de repaso.',
        RandomTestMode.markedReview => 'Marca preguntas durante un test para repasarlas aquí.',
      };
}
