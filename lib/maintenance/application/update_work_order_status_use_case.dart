import '../../core/error/failure.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';
import '../domain/work_order_status.dart';

/// Transición de estado de una orden. Siempre envía `expectedVersion`.
///
/// Solo existen las transiciones del backend: IN_PROGRESS, COMPLETED y
/// CANCELLED. COMPLETED (acciones correctivas) y CANCELLED (motivo) exigen
/// `summary`.
class UpdateWorkOrderStatusUseCase {
  final WorkOrderRepository _repository;

  UpdateWorkOrderStatusUseCase(this._repository);

  Future<WorkOrder> call(
    WorkOrder order,
    WorkOrderStatus status, {
    String? summary,
  }) async {
    const allowed = {
      WorkOrderStatus.inProgress,
      WorkOrderStatus.completed,
      WorkOrderStatus.cancelled,
    };
    if (!allowed.contains(status)) {
      throw ValidationFailure('Transición no permitida: ${status.name}.');
    }
    final text = summary?.trim();
    final needsSummary =
        status == WorkOrderStatus.completed || status == WorkOrderStatus.cancelled;
    if (needsSummary && (text == null || text.isEmpty)) {
      throw ValidationFailure(status == WorkOrderStatus.cancelled
          ? 'Indica el motivo de la cancelación.'
          : 'Indica las acciones correctivas realizadas.');
    }
    return _repository.updateStatus(
      id: order.id,
      status: status,
      summary: text,
      expectedVersion: order.version,
    );
  }
}
