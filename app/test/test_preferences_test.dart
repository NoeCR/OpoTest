import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testea_local/services/test_preferences.dart';

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
  });
}
