import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opotest/services/test_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TestPreferences', () {
    late TestPreferences prefs;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      prefs = TestPreferences();
    });

    test('load usa defaults cuando no hay valores guardados', () async {
      await prefs.load();
      expect(prefs.errorFormat, 100);
      expect(prefs.durationMinutes, 0);
      expect(prefs.examSimulation, isFalse);
      expect(prefs.simulacrumQuestions, 100);
      expect(prefs.simulacrumMinutes, 90);
    });

    test('setErrorFormat persiste y notifica', () async {
      var notified = 0;
      prefs.addListener(() => notified++);

      await prefs.setErrorFormat(25);
      expect(prefs.errorFormat, 25);
      expect(notified, 1);

      final sp = await SharedPreferences.getInstance();
      expect(sp.getInt('test_error_format'), 25);
    });

    test('setDurationMinutes y setExamSimulation persisten', () async {
      await prefs.setDurationMinutes(15);
      await prefs.setExamSimulation(true);

      final reloaded = TestPreferences();
      await reloaded.load();

      expect(reloaded.durationMinutes, 15);
      expect(reloaded.examSimulation, isTrue);
    });

    test('simulacro guarda preguntas y minutos aparte del test global', () async {
      await prefs.setDurationMinutes(15);
      await prefs.setSimulacrumQuestions(50);
      await prefs.setSimulacrumMinutes(60);

      final reloaded = TestPreferences();
      await reloaded.load();

      expect(reloaded.durationMinutes, 15);
      expect(reloaded.simulacrumQuestions, 50);
      expect(reloaded.simulacrumMinutes, 60);
    });

    test('simulacro recuerda las pruebas excluidas del pool', () async {
      await prefs.setSimulacrumPaperIncluded('paper_am_2025', false);
      expect(prefs.isSimulacrumPaperIncluded('paper_am_2025'), isFalse);
      expect(prefs.isSimulacrumPaperIncluded('paper_ja_2025'), isTrue);

      final reloaded = TestPreferences();
      await reloaded.load();
      expect(reloaded.isSimulacrumPaperIncluded('paper_am_2025'), isFalse);

      await reloaded.includeAllSimulacrumPapers();
      expect(reloaded.isSimulacrumPaperIncluded('paper_am_2025'), isTrue);

      await prefs.setSimulacrumPaperIncluded('paper_am_2025', false);
      await prefs.excludeSimulacrumPapers(['paper_inap_2024']);
      expect(prefs.isSimulacrumPaperIncluded('paper_am_2025'), isFalse);
      expect(prefs.isSimulacrumPaperIncluded('paper_inap_2024'), isFalse);

      await prefs.includeSimulacrumPapers(['paper_am_2025']);
      expect(prefs.isSimulacrumPaperIncluded('paper_am_2025'), isTrue);
      expect(prefs.isSimulacrumPaperIncluded('paper_inap_2024'), isFalse);
    });
  });
}
