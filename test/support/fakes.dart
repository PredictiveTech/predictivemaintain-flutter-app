import 'dart:typed_data';

import 'package:predictivemaintain_flutter_app/core/domain/file_exporter.dart';
import 'package:predictivemaintain_flutter_app/core/domain/paged_result.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_update.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/availability_report.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/comparison_row.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/criticality.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/report_range.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/report_repository.dart';
import 'package:predictivemaintain_flutter_app/subscription/domain/subscription.dart';
import 'package:predictivemaintain_flutter_app/subscription/domain/subscription_repository.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/user.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/user_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_detail.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_status.dart';
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

  User me = makeUser('me', 'Gerente Uno');
  String? renamedTo;

  @override
  Future<User> getMe() async => me;

  @override
  Future<User> updateDisplayName(String displayName) async {
    renamedTo = displayName;
    me = User(
        id: me.id, tenantId: me.tenantId, email: me.email, displayName: displayName,
        active: true, roles: me.roles);
    return me;
  }

  PagedResult<User> page_(List<User> items, int n, int total) => PagedResult(
      items: items, number: n, size: 2, totalElements: 99, totalPages: total);
}


AssetDetail makeAssetDetail({String id = 'asset1', bool active = true}) => AssetDetail(
      id: id,
      code: 'COMP-003',
      name: 'Compresor 3',
      location: 'Planta A',
      plantId: 'plant1',
      productionLine: 'L1',
      assetType: 'COMPRESSOR',
      criticality: Criticality.high,
      latitude: -12.04,
      longitude: -77.03,
      active: active,
    );

class FakeAssetRepository implements AssetRepository {
  AssetDetail detail = makeAssetDetail();
  Failure? failure;

  /// Si es true, la baja sin force responde 409 (órdenes abiertas).
  bool conflictUnlessForce = false;
  final deactivateCalls = <bool>[];
  AssetUpdate? lastUpdate;

  @override
  Future<PagedResult<Asset>> getAssets() async => pagedOf(<Asset>[
        const Asset(
          id: 'asset1',
          code: 'COMP-003',
          name: 'Compresor 3',
          location: 'Planta A',
          assetType: 'COMPRESSOR',
          criticality: Criticality.high,
          active: true,
          status: AssetStatus.operational,
          sensorTypes: [],
        ),
      ]);

  @override
  Future<AssetDetail> getAssetDetail(String id) async => detail;

  @override
  Future<List<SensorReading>> getSensors(String id) async => const [];

  @override
  Future<AssetDetail> updateAsset(String id, AssetUpdate u) async {
    lastUpdate = u;
    if (failure != null) throw failure!;
    detail = AssetDetail(
        id: id, code: detail.code, name: u.name, location: u.location, plantId: u.plantId,
        productionLine: u.productionLine, assetType: u.assetType, criticality: u.criticality,
        latitude: u.latitude, longitude: u.longitude, active: true);
    return detail;
  }

  @override
  Future<AssetDetail> deactivateAsset(String id, {bool force = false}) async {
    deactivateCalls.add(force);
    if (conflictUnlessForce && !force) throw const ConflictFailure('HTTP 409');
    if (failure != null) throw failure!;
    detail = makeAssetDetail(id: id, active: false);
    return detail;
  }
}

class FakeReportRepository implements ReportRepository {
  Failure? failure;
  final calls = <String>[];
  ReportRange? lastRange;
  List<String>? lastIds;
  AvailabilityReport? availability;
  List<ComparisonRow> rows = const [];

  @override
  Future<AvailabilityReport> getAvailability(String assetId, ReportRange range) async {
    calls.add('availability');
    lastRange = range;
    lastIds = [assetId];
    if (failure != null) throw failure!;
    return availability ??
        AvailabilityReport(
          assetId: assetId,
          assetCode: 'COMP-003',
          from: range.from,
          to: range.to,
          availabilityPercent: 98.5,
          downtime: const Duration(hours: 10, minutes: 30),
          period: const Duration(days: 30),
          hasEvents: true,
          events: [
            AssetEvent(
                type: AssetEventType.downtime,
                referenceId: 'd1',
                occurredAt: DateTime.utc(2026, 11, 1, 8),
                endedAt: DateTime.utc(2026, 11, 1, 10, 30)),
            AssetEvent(
                type: AssetEventType.alert,
                referenceId: 'al1',
                occurredAt: DateTime.utc(2026, 11, 2, 8),
                severity: 'CRITICAL',
                status: 'CONFIRMED'),
          ],
        );
  }

  @override
  Future<List<ComparisonRow>> compare(List<String> assetIds, ReportRange range) async {
    calls.add('compare');
    lastRange = range;
    lastIds = assetIds;
    if (failure != null) throw failure!;
    return rows;
  }

  @override
  Future<Uint8List> exportHistory(List<String> assetIds, ReportRange range) async {
    calls.add('export');
    lastRange = range;
    lastIds = assetIds;
    if (failure != null) throw failure!;
    return Uint8List.fromList('a,b\n1,2\n'.codeUnits);
  }
}

class FakeFileExporter implements FileExporter {
  String? fileName;
  Uint8List? bytes;
  String? mimeType;

  @override
  Future<void> saveAndShare({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    this.fileName = fileName;
    this.bytes = bytes;
    this.mimeType = mimeType;
  }
}

SubscriptionPlan makePlan(String id, String name, int limit, [double amount = 10]) =>
    SubscriptionPlan(id: id, name: name, assetLimit: limit, amount: amount, currency: 'USD');

Subscription makeSubscription({
  SubscriptionPlan? plan,
  int used = 9,
  int limit = 10,
  bool nearLimit = true,
  int days = 20,
}) =>
    Subscription(
      id: 's1',
      status: SubscriptionStatus.active,
      startsAt: DateTime.utc(2026, 10, 1),
      endsAt: DateTime.utc(2026, 12, 14, 12),
      monitoringAllowed: true,
      plan: plan ?? makePlan('p-basic', 'Básico', limit),
      capacity: Capacity(
          limit: limit, used: used, available: limit - used,
          usagePercent: used * 100 / limit, nearLimit: nearLimit),
      expiry: Expiry(daysRemaining: days, expiresSoon: days <= 7, expired: false),
    );

class FakeSubscriptionRepository implements SubscriptionRepository {
  Subscription subscription = makeSubscription();
  List<SubscriptionPlan> plans = [
    makePlan('p-pro', 'Pro', 50, 99),
    makePlan('p-basic', 'Básico', 10, 29),
    makePlan('p-free', 'Inicial', 3, 0),
  ];
  Failure? changeFailure;
  String? requestedPlan;

  @override
  Future<Subscription> getSubscription() async => subscription;

  @override
  Future<List<SubscriptionPlan>> getPlans() async => plans;

  @override
  Future<Subscription> changePlan(String planId) async {
    requestedPlan = planId;
    if (changeFailure != null) throw changeFailure!;
    final plan = plans.firstWhere((p) => p.id == planId);
    subscription = makeSubscription(plan: plan, used: subscription.capacity.used, limit: plan.assetLimit, nearLimit: false);
    return subscription;
  }
}
