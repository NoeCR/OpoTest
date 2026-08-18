enum ContentKind { tests, exams, official, own }

extension ContentKindX on ContentKind {
  String get label => switch (this) {
        ContentKind.tests => 'Tests',
        ContentKind.exams => 'Exámenes',
        ContentKind.official => 'Preguntas oficiales',
        ContentKind.own => 'Preguntas propias',
      };

  String get dbType => switch (this) {
        ContentKind.tests => 'test',
        ContentKind.exams => 'exam',
        ContentKind.official => 'realexam',
        ContentKind.own => 'own',
      };
}
