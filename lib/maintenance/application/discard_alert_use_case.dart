import '../../core/error/failure.dart';
import '../domain/alert.dart';
import '../domain/alert_repository.dart';
import '../domain/alert_status.dart';

/// Descarta una alerta; el motivo es obligatorio (máx. 500 caracteres).
class DiscardAlertUseCase {
  static const maxReasonLength = 500;

  final AlertRepository _repository;

  DiscardAlertUseCase(this._repository);

  Future<Alert> call(Alert alert, String reason) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Indica el motivo del descarte.');
    }
    if (trimmed.length > maxReasonLength) {
      throw const ValidationFailure(
          'El motivo no puede superar los 500 caracteres.');
    }
    return _repository.updateStatus(
      id: alert.id,
      status: AlertStatus.discarded,
      reason: trimmed,
      expectedVersion: alert.version,
    );
  }
}
