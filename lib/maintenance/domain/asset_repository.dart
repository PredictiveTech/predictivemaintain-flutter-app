import 'asset.dart';
import 'asset_detail.dart';
import '../../core/domain/paged_result.dart';
import 'sensor_reading.dart';

abstract interface class AssetRepository {
  Future<PagedResult<Asset>> getAssets();
  Future<AssetDetail> getAssetDetail(String assetId);
  Future<List<SensorReading>> getSensors(String assetId);
}
