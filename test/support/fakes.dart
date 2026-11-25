import 'package:predictivemaintain_flutter_app/core/domain/paged_result.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/user.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/user_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_detail.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/sensor_reading.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_diagnostic.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/severity.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_status.dart';

PagedResult<T> pagedOf<T>(List<T> items, {int number = 0, int totalPages = 1}) => PagedResult(
    items: items,
    number: number,
    size: 20,
    totalElements: items.length,
    totalPages: totalPages);

Alert makeAlert({
  String id = 'a1',
  AlertStatus status = AlertStatus.inReview,
  Severity severity = Severity.critical,
  int version = 3,
  AlertDiagnostic? diagnostic,
}) =>
    Alert(
      id: id,
      assetId: 'asset1',
      assetCode: 'COMP-003',
      assetName: 'Compresor 3',
      severity: severity,
      status: status,
      raisedAt: DateTime.utc(2026, 10, 10, 3, 44),
      version: version,
      diagnostic: diagnostic ??
          AlertDiagnostic(
            metric: 'TEMPERATURE',
            unit: '°C',
            observedValue: 101.25,
            lowerBound: 20,
            upperBound: 85,
            measuredAt: DateTime.utc(2026, 10, 10, 3, 44),
          ),
    );

WorkOrder makeOrder({
  String id = 'w1',
  WorkOrderStatus status = WorkOrderStatus.open,
  String? assignedUserId,
  int version = 5,
  Severity severity = Severity.critical,
}) =>
    WorkOrder(
      id: id,
      alertId: 'a1',
      assetId: 'asset1',
      assetCode: 'COMP-003',
      assetName: 'Compresor 3',
      severity: severity,
      status: status,
      summary: 'Resumen',
      openedAt: DateTime.utc(2026, 10, 11),
      version: version,
      assignedUserId: assignedUserId,
    );

User makeUser(String id, String name) => User(
    id: id, tenantId: 't', email: '$id@x.com', displayName: name, active: true, roles: const ['TECHNICIAN']);

/// Repositorio de alertas en memoria que registra las llamadas.
class FakeAlertRepository implements AlertRepository {
  List<Alert> alerts;
  Failure? failure;
  final calls = <String>[];
  Map<String, Object?>? lastUpdate;

  FakeAlertRepository([this.alerts = const []]);

  @override
  Future<PagedResult<Alert>> getAlerts({AlertStatus? status, Severity? severity, int page = 0}) async {
    calls.add('getAlerts status=$status severity=$severity page=$page');
    if (failure != null) throw failure!;
    return page_(alerts.where((a) =>
        (status == null || a.status == status) && (severity == null || a.severity == severity)).toList());
  }

  PagedResult<Alert> page_(List<Alert> l) => pagedOf(l);

  @override
  Future<Alert> getAlert(String id) async {
    if (failure != null) throw failure!;
    return alerts.firstWhere((a) => a.id == id);
  }

  @override
  Future<Alert> updateStatus({
    required String id,
    required AlertStatus status,
    String? reason,
    int? expectedVersion,
  }) async {
    lastUpdate = {'id': id, 'status': status, 'reason': reason, 'expectedVersion': expectedVersion};
    if (failure != null) throw failure!;
    final old = alerts.firstWhere((a) => a.id == id);
    final updated = makeAlert(id: id, status: status, version: old.version + 1);
    alerts = [for (final a in alerts) a.id == id ? updated : a];
    return updated;
  }
}

class FakeWorkOrderRepository implements WorkOrderRepository {
  List<WorkOrder> orders;
  Failure? failure;
  Map<String, Object?>? last;

  FakeWorkOrderRepository([this.orders = const []]);

  @override
  Future<PagedResult<WorkOrder>> getWorkOrders({WorkOrderStatus? status, int page = 0}) async {
    if (failure != null) throw failure!;
    return pagedOf(orders.where((o) => status == null || o.status == status).toList());
  }

  @override
  Future<WorkOrder> getWorkOrder(String id) async {
    if (failure != null) throw failure!;
    return orders.firstWhere((o) => o.id == id);
  }

  @override
  Future<WorkOrder> create(String alertId) async {
    last = {'op': 'create', 'alertId': alertId};
    if (failure != null) throw failure!;
    final o = makeOrder(id: 'new');
    orders = [o, ...orders];
    return o;
  }

  @override
  Future<WorkOrder> assign({
    required String id,
    required String technicianId,
    required int expectedVersion,
  }) async {
    last = {'op': 'assign', 'id': id, 'technicianId': technicianId, 'expectedVersion': expectedVersion};
    if (failure != null) throw failure!;
    final o = makeOrder(id: id, status: WorkOrderStatus.assigned, assignedUserId: technicianId, version: expectedVersion + 1);
    orders = [for (final x in orders) x.id == id ? o : x];
    return o;
  }

  @override
  Future<WorkOrder> updateStatus({
    required String id,
    required WorkOrderStatus status,
    String? summary,
    required int expectedVersion,
  }) async {
    last = {'op': 'status', 'id': id, 'status': status, 'summary': summary, 'expectedVersion': expectedVersion};
    if (failure != null) throw failure!;
    final o = makeOrder(id: id, status: status, version: expectedVersion + 1);
    orders = [for (final x in orders) x.id == id ? o : x];
    return o;
  }
}

class FakeUserRepository implements UserRepository {
  final List<List<User>> pages;
  final requested = <int>[];
  String? lastRole;
  bool? lastActive;

  FakeUserRepository(this.pages);

  @override
  Future<PagedResult<User>> getUsers({String? role, bool? active, int page = 0}) async {
    lastRole = role;
    lastActive = active;
    requested.add(page);
    return page_(pages[page], page, pages.length);
  }

  PagedResult<User> page_(List<User> items, int n, int total) => PagedResult(
      items: items, number: n, size: 2, totalElements: 99, totalPages: total);
}

class FakeAssetsEmpty implements AssetRepository {
  @override
  Future<PagedResult<Asset>> getAssets() async => pagedOf(<Asset>[]);
  @override
  Future<AssetDetail> getAssetDetail(String id) => throw UnimplementedError();
  @override
  Future<List<SensorReading>> getSensors(String id) => throw UnimplementedError();
}
