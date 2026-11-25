import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';

class GetWorkOrderUseCase {
  final WorkOrderRepository _repository;

  GetWorkOrderUseCase(this._repository);

  Future<WorkOrder> call(String id) => _repository.getWorkOrder(id);
}
