import '../../core/network/api_client.dart';
import '../domain/paged_result.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';
import 'paged_response_dto.dart';
import 'work_order_dto.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  final ApiClient _api;

  WorkOrderRepositoryImpl(this._api);

  @override
  Future<PagedResult<WorkOrder>> getWorkOrders() async {
    final json = await _api.get('/work-orders');
    return parseResponse(
      () => PagedResponseDto.fromJson(json as Map<String, dynamic>, WorkOrderDto.fromJson)
          .toDomain((dto) => dto.toDomain()),
    );
  }
}
