import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../iam/application/login_use_case.dart';
import '../iam/application/logout_use_case.dart';
import '../iam/application/restore_session_use_case.dart';
import '../iam/domain/auth_repository.dart';
import '../iam/domain/auth_session_store.dart';
import '../iam/infrastructure/auth_repository_impl.dart';
import '../iam/infrastructure/secure_auth_session_store.dart';
import 'session_controller.dart';
import '../maintenance/application/get_alerts_use_case.dart';
import '../maintenance/application/get_asset_detail_use_case.dart';
import '../maintenance/application/get_asset_sensors_use_case.dart';
import '../maintenance/application/get_assets_use_case.dart';
import '../maintenance/application/get_work_orders_use_case.dart';
import '../maintenance/domain/alert_repository.dart';
import '../maintenance/domain/asset_repository.dart';
import '../maintenance/domain/work_order_repository.dart';
import '../maintenance/infrastructure/alert_repository_impl.dart';
import '../maintenance/infrastructure/asset_repository_impl.dart';
import '../maintenance/infrastructure/work_order_repository_impl.dart';

/// Raíz de composición: único lugar que une infraestructura con aplicación.

// --- core ---

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => SecureAuthSessionStore(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: baseUrl,
    tokenProvider: () async =>
        (await ref.read(authSessionStoreProvider).read())?.accessToken,
    // Lectura diferida: evita el ciclo apiClient -> sessionController -> apiClient.
    onUnauthorized: () =>
        ref.read(sessionControllerProvider.notifier).onUnauthorized(),
  );
  ref.onDispose(client.close);
  return client;
});

// --- iam ---

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(apiClientProvider)),
);

final loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(authSessionStoreProvider),
  ),
);

final restoreSessionUseCaseProvider = Provider(
  (ref) => RestoreSessionUseCase(ref.watch(authSessionStoreProvider)),
);

final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.watch(authSessionStoreProvider)),
);

// --- maintenance ---

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => AssetRepositoryImpl(ref.watch(apiClientProvider)),
);

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepositoryImpl(ref.watch(apiClientProvider)),
);

final workOrderRepositoryProvider = Provider<WorkOrderRepository>(
  (ref) => WorkOrderRepositoryImpl(ref.watch(apiClientProvider)),
);

final getAssetsUseCaseProvider =
    Provider((ref) => GetAssetsUseCase(ref.watch(assetRepositoryProvider)));
final getAssetDetailUseCaseProvider =
    Provider((ref) => GetAssetDetailUseCase(ref.watch(assetRepositoryProvider)));
final getAssetSensorsUseCaseProvider =
    Provider((ref) => GetAssetSensorsUseCase(ref.watch(assetRepositoryProvider)));
final getAlertsUseCaseProvider =
    Provider((ref) => GetAlertsUseCase(ref.watch(alertRepositoryProvider)));
final getWorkOrdersUseCaseProvider =
    Provider((ref) => GetWorkOrdersUseCase(ref.watch(workOrderRepositoryProvider)));
