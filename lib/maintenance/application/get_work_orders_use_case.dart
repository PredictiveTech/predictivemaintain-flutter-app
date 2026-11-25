import '../../core/domain/paged_result.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';
import '../domain/work_order_status.dart';

class GetWorkOrdersUseCase {
  final WorkOrderRepository _repository;

  GetWorkOrdersUseCase(this._repository);

  Future<PagedResult<WorkOrder>> call({WorkOrderStatus? status, int page = 0}) =>
      _repository.getWorkOrders(status: status, page: page);
}
