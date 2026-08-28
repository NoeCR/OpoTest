import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/random_tests/domain/random_test_constants.dart';

void main() {
  test('isSyntheticAttemptTestId cubre mixto, refuerzo, repaso y simulacro', () {
    expect(RandomTestConstants.isSyntheticAttemptTestId('mixed_random_1'), isTrue);
    expect(RandomTestConstants.isSyntheticAttemptTestId('reinforcement_random_1'), isTrue);
    expect(RandomTestConstants.isSyntheticAttemptTestId('review_random_1'), isTrue);
    expect(RandomTestConstants.isSyntheticAttemptTestId('simulacrum_random_1'), isTrue);
    expect(RandomTestConstants.isSyntheticAttemptTestId('1001'), isFalse);
  });
}
