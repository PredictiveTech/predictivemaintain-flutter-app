import '../../core/error/failure.dart';
import '../domain/alert.dart';
import '../domain/alert_status.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';

/// Genera la orden de trabajo de una alerta confirmada (US-07).
///
/// El backend (CreateWorkOrderResource) solo recibe `alertId`: la orden nace
/// OPEN y sin asignar, y responde 409 si la alerta no está confirmada o ya
/// tiene orden.
class CreateWorkOrderUseCase {
  final WorkOrderRepository _repository;

  CreateWorkOrderUseCase(this._repository);

  Future<WorkOrder> call(Alert alert) async {
    if (alert.status != AlertStatus.confirmed) {
      throw const ConflictFailure('La alerta debe estar confirmada.');
    }
    return _repository.create(alert.id);
  }
}
