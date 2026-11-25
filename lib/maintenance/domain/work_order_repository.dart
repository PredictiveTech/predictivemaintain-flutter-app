import 'paged_result.dart';
import 'work_order.dart';

abstract interface class WorkOrderRepository {
  Future<PagedResult<WorkOrder>> getWorkOrders();
}
