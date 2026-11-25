import '../../core/error/failure.dart';
import '../domain/asset_detail.dart';
import '../domain/asset_repository.dart';
import '../domain/work_order.dart';
import '../domain/work_order_repository.dart';
import '../domain/work_order_status.dart';

sealed class DeactivateAssetResult {
  const DeactivateAssetResult();
}

class AssetDeactivated extends DeactivateAssetResult {
  final AssetDetail asset;
  const AssetDeactivated(this.asset);
}

/// El backend avisó (409) de que hay órdenes abiertas: hace falta confirmar.
class AssetNeedsConfirmation extends DeactivateAssetResult {
  final int openWorkOrders;
  const AssetNeedsConfirmation(this.openWorkOrders);
}

/// Baja de un activo (US-13).
///
/// Primero sin `force`. Si el backend responde 409 (órdenes abiertas), cuenta
/// cuántas son y devuelve [AssetNeedsConfirmation]; solo con `force: true`
/// se repite la baja forzada. El cuerpo del 409 no está documentado en el
/// OpenAPI, por eso el conteo sale de GET /work-orders (abiertas = OPEN,
/// ASSIGNED o IN_PROGRESS del activo).
class DeactivateAssetUseCase {
  static const openStatuses = [
    WorkOrderStatus.open,
    WorkOrderStatus.assigned,
    WorkOrderStatus.inProgress,
  ];

  final AssetRepository _assets;
  final WorkOrderRepository _orders;

  DeactivateAssetUseCase(this._assets, this._orders);

  Future<DeactivateAssetResult> call(String assetId, {bool force = false}) async {
    try {
      return AssetDeactivated(await _assets.deactivateAsset(assetId, force: force));
    } on ConflictFailure {
      if (force) rethrow;
      return AssetNeedsConfirmation(await _countOpenOrders(assetId));
    }
  }

  Future<int> _countOpenOrders(String assetId) async {
    var count = 0;
    for (final status in openStatuses) {
      var page = 0;
      while (true) {
        final result = await _orders.getWorkOrders(status: status, page: page);
        count += result.items.where((WorkOrder o) => o.assetId == assetId).length;
        page++;
        if (page >= result.totalPages) break;
      }
    }
    return count;
  }
}
