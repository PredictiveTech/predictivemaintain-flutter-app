import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';

/// Asigna o reasigna la orden a un técnico (US-08). Envía la versión vista
/// para detectar cambios concurrentes (409).
class AssignWorkOrderUseCase {
  final WorkOrderRepository _repository;

  AssignWorkOrderUseCase(this._repository);

  Future<WorkOrder> call(WorkOrder order, String technicianId) =>
      _repository.assign(
        id: order.id,
        technicianId: technicianId,
        expectedVersion: order.version,
      );
}
