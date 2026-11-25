import '../../core/domain/paged_result.dart';
import '../domain/alert.dart';
import '../domain/alert_repository.dart';
import '../domain/alert_status.dart';
import '../domain/severity.dart';

class GetAlertsUseCase {
  final AlertRepository _repository;

  GetAlertsUseCase(this._repository);

  Future<PagedResult<Alert>> call({AlertStatus? status, Severity? severity, int page = 0}) =>
      _repository.getAlerts(status: status, severity: severity, page: page);
}
