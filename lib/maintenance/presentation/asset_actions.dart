import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/failure.dart';
import '../application/deactivate_asset_use_case.dart';
import '../domain/asset_update.dart';
import 'maintenance_providers.dart';

/// Acciones sobre la ficha de un activo: editar y dar de baja.
class AssetActions extends AsyncNotifier<void> {
  @override
  void build() {}

  void _refresh(String id) {
    ref.invalidate(assetDetailProvider(id));
    ref.invalidate(assetsProvider);
  }

  Future<bool> save(String id, AssetUpdate update) async {
    state = const AsyncLoading();
    try {
      await ref.read(updateAssetUseCaseProvider)(id, update);
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
      return false;
    }
    state = const AsyncData(null);
    _refresh(id);
    return true;
  }

  /// Devuelve el resultado de la baja, o null si falló (el error queda en el
  /// estado). Con [force] repite la baja pese a las órdenes abiertas.
  Future<DeactivateAssetResult?> deactivate(String id, {bool force = false}) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(deactivateAssetUseCaseProvider)(id, force: force);
      state = const AsyncData(null);
      if (result is AssetDeactivated) _refresh(id);
      return result;
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
      return null;
    }
  }
}

final assetActionsProvider =
    AsyncNotifierProvider.autoDispose<AssetActions, void>(AssetActions.new);
