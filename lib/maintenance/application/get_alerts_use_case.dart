import '../domain/alert.dart';
import '../domain/alert_repository.dart';
import '../domain/paged_result.dart';

class GetAlertsUseCase {
  final AlertRepository _repository;

  GetAlertsUseCase(this._repository);

  Future<PagedResult<Alert>> call() => _repository.getAlerts();
}
