import '../domain/alert.dart';
import '../domain/alert_repository.dart';
import '../domain/alert_status.dart';

/// Confirma una alerta que el gerente considera real (US-05).
class ConfirmAlertUseCase {
  final AlertRepository _repository;

  ConfirmAlertUseCase(this._repository);

  Future<Alert> call(Alert alert) => _repository.updateStatus(
        id: alert.id,
        status: AlertStatus.confirmed,
        expectedVersion: alert.version,
      );
}
