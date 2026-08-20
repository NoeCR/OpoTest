import '../../../models/question.dart';

enum RandomTestMode {
  classic,
  practiced,
  refresh,
  mostErrors,
  mixed,
}

extension RandomTestModeLabels on RandomTestMode {
  String get title => switch (this) {
        RandomTestMode.classic => 'Al azar',
        RandomTestMode.practiced => 'Temario practicado',
        RandomTestMode.refresh => 'Refrescar olvidados',
        RandomTestMode.mostErrors => 'Más fallos recientes',
        RandomTestMode.mixed => 'Mixto multisección',
      };

  String get subtitle => switch (this) {
        RandomTestMode.classic => 'Cualquier test del temario importado',
        RandomTestMode.practiced => 'Solo tests que ya has completado',
        RandomTestMode.refresh => 'Tests sin repetir hace tiempo o muy largos',
        RandomTestMode.mostErrors => 'Prioriza donde más fallaste la última vez',
        RandomTestMode.mixed => 'Preguntas aleatorias de varias leyes',
      };

  String get emptyHint => switch (this) {
        RandomTestMode.classic => 'Importa el temario para practicar.',
        RandomTestMode.practiced => 'Completa al menos un test para usar este modo.',
        RandomTestMode.refresh => 'Necesitas intentos previos para detectar tests olvidados.',
        RandomTestMode.mostErrors => 'Completa tests con fallos para usar este modo.',
        RandomTestMode.mixed => 'Importa el temario para generar un mix.',
      };
}

class RandomTestPick {
  const RandomTestPick.test(this.testId)
      : mixedTest = null,
        emptyMessage = null;

  const RandomTestPick.mixed(this.mixedTest)
      : testId = null,
        emptyMessage = null;

  const RandomTestPick.empty(this.emptyMessage)
      : testId = null,
        mixedTest = null;

  final String? testId;
  final TestDefinition? mixedTest;
  final String? emptyMessage;

  bool get isEmpty => emptyMessage != null;
}
