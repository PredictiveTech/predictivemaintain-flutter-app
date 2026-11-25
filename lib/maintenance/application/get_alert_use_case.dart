import '../domain/alert.dart';
import '../domain/alert_repository.dart';

class GetAlertUseCase {
  final AlertRepository _repository;

  GetAlertUseCase(this._repository);

  Future<Alert> call(String id) => _repository.getAlert(id);
}
