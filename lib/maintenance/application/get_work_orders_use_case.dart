import '../domain/paged_result.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';

class GetWorkOrdersUseCase {
  final WorkOrderRepository _repository;

  GetWorkOrdersUseCase(this._repository);

  Future<PagedResult<WorkOrder>> call() => _repository.getWorkOrders();
}
