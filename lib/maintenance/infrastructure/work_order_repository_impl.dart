import '../../core/domain/paged_result.dart';
import '../../core/network/api_client.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';
import '../domain/work_order_status.dart';
import 'enum_parser.dart';
import 'paged_response_dto.dart';
import 'work_order_dto.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  final ApiClient _api;

  WorkOrderRepositoryImpl(this._api);

  WorkOrder _one(dynamic json) => parseResponse(
        () => WorkOrderDto.fromJson(json as Map<String, dynamic>).toDomain(),
      );

  @override
  Future<PagedResult<WorkOrder>> getWorkOrders({
    WorkOrderStatus? status,
    int page = 0,
  }) async {
    final json = await _api.get('/work-orders', query: {
      'status': status == null ? null : apiName(status),
      'page': page == 0 ? null : '$page',
    });
    return parseResponse(
      () => PagedResponseDto.fromJson(json as Map<String, dynamic>, WorkOrderDto.fromJson)
          .toDomain((dto) => dto.toDomain()),
    );
  }

  @override
  Future<WorkOrder> getWorkOrder(String id) async => _one(await _api.get('/work-orders/$id'));

  @override
  Future<WorkOrder> create(String alertId) async =>
      _one(await _api.post('/work-orders', body: {'alertId': alertId}));

  @override
  Future<WorkOrder> assign({
    required String id,
    required String technicianId,
    required int expectedVersion,
  }) async =>
      _one(await _api.patch('/work-orders/$id/assign', body: {
        'technicianId': technicianId,
        'expectedVersion': expectedVersion,
      }));

  @override
  Future<WorkOrder> updateStatus({
    required String id,
    required WorkOrderStatus status,
    String? summary,
    required int expectedVersion,
  }) async =>
      _one(await _api.patch('/work-orders/$id/status', body: {
        'status': apiName(status),
        'summary': ?summary,
        'expectedVersion': expectedVersion,
      }));
}
