import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/domain/paged_result.dart';
import '../../core/error/retry.dart';
import '../../iam/domain/user.dart';
import '../domain/alert.dart';
import '../domain/alert_status.dart';
import '../domain/asset.dart';
import '../domain/asset_detail.dart';
import '../domain/sensor_reading.dart';
import '../domain/severity.dart';
import '../domain/work_order.dart';
import '../domain/work_order_status.dart';
import 'paged_list_notifier.dart';

// autoDispose: al cerrar sesión se destruye la pantalla y con ella los datos,
// de modo que otro usuario nunca ve datos en caché del anterior.

final assetsProvider = FutureProvider.autoDispose<List<Asset>>(
  (ref) async => (await ref.watch(getAssetsUseCaseProvider)()).items,
  retry: noRetry,
);

/// Detalle y sensores son proveedores separados: cada uno falla de forma
/// independiente, como antes.
final assetDetailProvider =
    FutureProvider.autoDispose.family<AssetDetail, String>(
  (ref, id) => ref.watch(getAssetDetailUseCaseProvider)(id),
  retry: noRetry,
);

final assetSensorsProvider =
    FutureProvider.autoDispose.family<List<SensorReading>, String>(
  (ref, id) => ref.watch(getAssetSensorsUseCaseProvider)(id),
  retry: noRetry,
);

// --- Alertas ---

/// Valores constantes: la selección "Todos" es null.
const alertSeverityOptions = [Severity.critical, Severity.warning];
const alertStatusOptions = AlertStatus.values;

class AlertStatusFilter extends Notifier<AlertStatus?> {
  @override
  AlertStatus? build() => null;
  void select(AlertStatus? v) => state = v;
}

class AlertSeverityFilter extends Notifier<Severity?> {
  @override
  Severity? build() => null;
  void select(Severity? v) => state = v;
}

final alertStatusFilterProvider =
    NotifierProvider.autoDispose<AlertStatusFilter, AlertStatus?>(AlertStatusFilter.new);
final alertSeverityFilterProvider =
    NotifierProvider.autoDispose<AlertSeverityFilter, Severity?>(AlertSeverityFilter.new);

class AlertsController extends PagedListNotifier<Alert> {
  @override
  Future<PagedResult<Alert>> fetch(int page) {
    final status = ref.read(alertStatusFilterProvider);
    final severity = ref.read(alertSeverityFilterProvider);
    return ref.read(getAlertsUseCaseProvider)(status: status, severity: severity, page: page);
  }

  @override
  Future<PagedList<Alert>> build() {
    // Cambiar un filtro reconstruye (y recarga desde la página 0).
    ref.watch(alertStatusFilterProvider);
    ref.watch(alertSeverityFilterProvider);
    return super.build();
  }
}

final alertsProvider = AsyncNotifierProvider.autoDispose<AlertsController, PagedList<Alert>>(
  AlertsController.new,
  retry: noRetry,
);

final alertDetailProvider = FutureProvider.autoDispose.family<Alert, String>(
  (ref, id) => ref.watch(getAlertUseCaseProvider)(id),
  retry: noRetry,
);

// --- Órdenes de trabajo ---

const workOrderStatusOptions = WorkOrderStatus.values;

class WorkOrderStatusFilter extends Notifier<WorkOrderStatus?> {
  @override
  WorkOrderStatus? build() => null;
  void select(WorkOrderStatus? v) => state = v;
}

/// El backend no filtra órdenes por severidad (GET /work-orders solo acepta
/// `status`), así que este filtro se aplica en el cliente sobre lo cargado.
class WorkOrderSeverityFilter extends Notifier<Severity?> {
  @override
  Severity? build() => null;
  void select(Severity? v) => state = v;
}

final workOrderStatusFilterProvider = NotifierProvider.autoDispose<WorkOrderStatusFilter,
    WorkOrderStatus?>(WorkOrderStatusFilter.new);
final workOrderSeverityFilterProvider =
    NotifierProvider.autoDispose<WorkOrderSeverityFilter, Severity?>(
        WorkOrderSeverityFilter.new);

class WorkOrdersController extends PagedListNotifier<WorkOrder> {
  @override
  Future<PagedResult<WorkOrder>> fetch(int page) => ref.read(getWorkOrdersUseCaseProvider)(
        status: ref.read(workOrderStatusFilterProvider),
        page: page,
      );

  @override
  Future<PagedList<WorkOrder>> build() {
    ref.watch(workOrderStatusFilterProvider);
    return super.build();
  }
}

final workOrdersProvider =
    AsyncNotifierProvider.autoDispose<WorkOrdersController, PagedList<WorkOrder>>(
  WorkOrdersController.new,
  retry: noRetry,
);

final workOrderDetailProvider = FutureProvider.autoDispose.family<WorkOrder, String>(
  (ref, id) => ref.watch(getWorkOrderUseCaseProvider)(id),
  retry: noRetry,
);

final techniciansProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(getTechniciansUseCaseProvider)(),
  retry: noRetry,
);
