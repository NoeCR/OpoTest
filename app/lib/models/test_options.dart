class TestOptions {
  TestOptions._();

  static const errorFormats = {
    0: 'No resta',
    25: '0,25',
    33: '0,33',
    50: '0,50',
    100: '1',
  };

  static const durations = [0, 5, 10, 15, 20, 25, 30];

  static String durationLabel(int minutes) =>
      minutes == 0 ? 'Sin límite' : '$minutes min';
}
