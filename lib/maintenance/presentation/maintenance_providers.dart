import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/retry.dart';
import '../domain/alert.dart';
import '../domain/asset.dart';
import '../domain/asset_detail.dart';
import '../domain/sensor_reading.dart';
import '../domain/work_order.dart';

// autoDispose: al cerrar sesión se destruye la pantalla y con ella los datos,
// de modo que otro usuario nunca ve datos en caché del anterior.

final assetsProvider = FutureProvider.autoDispose<List<Asset>>(
  (ref) async => (await ref.watch(getAssetsUseCaseProvider)()).items,
  retry: noRetry,
);

final alertsProvider = FutureProvider.autoDispose<List<Alert>>(
  (ref) async => (await ref.watch(getAlertsUseCaseProvider)()).items,
  retry: noRetry,
);

final workOrdersProvider = FutureProvider.autoDispose<List<WorkOrder>>(
  (ref) async => (await ref.watch(getWorkOrdersUseCaseProvider)()).items,
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
