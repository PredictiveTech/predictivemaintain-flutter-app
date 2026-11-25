import '../../core/domain/paged_result.dart';
import 'asset.dart';
import 'asset_detail.dart';
import 'asset_update.dart';
import 'sensor_reading.dart';

abstract interface class AssetRepository {
  Future<PagedResult<Asset>> getAssets();
  Future<AssetDetail> getAssetDetail(String assetId);
  Future<List<SensorReading>> getSensors(String assetId);
  Future<AssetDetail> updateAsset(String assetId, AssetUpdate update);

  /// Baja lógica. Sin [force], el backend responde 409 (`ConflictFailure`) si
  /// el activo tiene órdenes de trabajo abiertas.
  Future<AssetDetail> deactivateAsset(String assetId, {bool force = false});
}
