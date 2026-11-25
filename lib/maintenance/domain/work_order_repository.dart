import 'paged_result.dart';
import 'work_order.dart';
import 'work_order_status.dart';

abstract interface class WorkOrderRepository {
  Future<PagedResult<WorkOrder>> getWorkOrders({
    WorkOrderStatus? status,
    int page = 0,
  });

  Future<WorkOrder> getWorkOrder(String id);

  /// Crea la orden (queda OPEN y sin asignar) a partir de una alerta confirmada.
  Future<WorkOrder> create(String alertId);

  Future<WorkOrder> assign({
    required String id,
    required String technicianId,
    required int expectedVersion,
  });

  Future<WorkOrder> updateStatus({
    required String id,
    required WorkOrderStatus status,
    String? summary,
    required int expectedVersion,
  });
}
