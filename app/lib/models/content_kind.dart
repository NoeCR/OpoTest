enum ContentKind { tests, exams, official, officialPaper, own }

extension ContentKindX on ContentKind {
  /// Pestañas de Legislación: las pruebas reales no van por ley, solo al simulacro.
  static const lawTabs = [
    ContentKind.tests,
    ContentKind.exams,
    ContentKind.official,
    ContentKind.own,
  ];

  String get label => switch (this) {
        ContentKind.tests => 'Tests',
        ContentKind.exams => 'Exámenes',
        ContentKind.official => 'Preguntas oficiales',
        ContentKind.officialPaper => 'Pruebas reales',
        ContentKind.own => 'Preguntas propias',
      };

  String get dbType => switch (this) {
        ContentKind.tests => 'test',
        ContentKind.exams => 'exam',
        ContentKind.official => 'realexam',
        ContentKind.officialPaper => 'officialpaper',
        ContentKind.own => 'own',
      };
}
