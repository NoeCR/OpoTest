import '../domain/custom_test_draft.dart';
import '../domain/custom_test_repository.dart';
import '../domain/custom_test_validation.dart';

class CustomTestService {
  CustomTestService(this._repository);

  final CustomTestRepository _repository;

  Future<List<CustomTestSummary>> listSummaries({String? lawId}) {
    return _repository.listSummaries(lawId: lawId);
  }

  Future<CustomTestDraft?> getDraft(String testId) {
    return _repository.getDraft(testId);
  }

  Future<String> save(CustomTestDraft draft) {
    validateCustomTestDraft(draft);
    return _repository.save(draft);
  }

  Future<void> delete(String testId) {
    return _repository.delete(testId);
  }
}
