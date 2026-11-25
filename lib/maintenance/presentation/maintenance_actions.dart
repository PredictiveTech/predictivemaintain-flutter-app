import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/failure.dart';
import '../domain/alert.dart';
import '../domain/work_order.dart';
import '../domain/work_order_status.dart';
import 'maintenance_providers.dart';

/// Acciones del gerente sobre alertas. El estado es loading mientras se
/// ejecuta y error (un [Failure]) si falla; las pantallas lo escuchan.
class AlertActions extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> _run(Future<Alert> Function() action, String alertId) async {
    state = const AsyncLoading();
    try {
      await action();
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
      return false;
    }
    state = const AsyncData(null);
    ref.invalidate(alertDetailProvider(alertId));
    ref.invalidate(alertsProvider);
    return true;
  }

  Future<bool> confirm(Alert alert) =>
      _run(() => ref.read(confirmAlertUseCaseProvider)(alert), alert.id);

  Future<bool> discard(Alert alert, String reason) =>
      _run(() => ref.read(discardAlertUseCaseProvider)(alert, reason), alert.id);
}

final alertActionsProvider =
    AsyncNotifierProvider.autoDispose<AlertActions, void>(AlertActions.new);

/// Acciones del gerente sobre órdenes de trabajo.
class WorkOrderActions extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<WorkOrder?> _run(Future<WorkOrder> Function() action, {String? refresh}) async {
    state = const AsyncLoading();
    try {
      final order = await action();
      state = const AsyncData(null);
      if (refresh != null) ref.invalidate(workOrderDetailProvider(refresh));
      ref.invalidate(workOrdersProvider);
      return order;
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
      return null;
    }
  }

  /// Devuelve la orden creada (para navegar a su detalle) o null si falló.
  Future<WorkOrder?> create(Alert alert) =>
      _run(() => ref.read(createWorkOrderUseCaseProvider)(alert));

  Future<bool> assign(WorkOrder order, String technicianId) async =>
      await _run(() => ref.read(assignWorkOrderUseCaseProvider)(order, technicianId),
          refresh: order.id) !=
      null;

  Future<bool> cancel(WorkOrder order, String reason) async =>
      await _run(
        () => ref.read(updateWorkOrderStatusUseCaseProvider)(
          order,
          WorkOrderStatus.cancelled,
          summary: reason,
        ),
        refresh: order.id,
      ) !=
      null;
}

final workOrderActionsProvider =
    AsyncNotifierProvider.autoDispose<WorkOrderActions, void>(WorkOrderActions.new);
