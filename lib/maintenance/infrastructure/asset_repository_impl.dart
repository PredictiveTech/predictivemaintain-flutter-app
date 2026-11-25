import '../../core/network/api_client.dart';
import '../domain/asset.dart';
import '../domain/asset_detail.dart';
import '../domain/asset_repository.dart';
import '../domain/asset_update.dart';
import '../../core/domain/paged_result.dart';
import '../domain/sensor_reading.dart';
import 'asset_detail_dto.dart';
import 'asset_dto.dart';
import 'enum_parser.dart';
import 'paged_response_dto.dart';
import 'sensor_reading_dto.dart';

class AssetRepositoryImpl implements AssetRepository {
  final ApiClient _api;

  AssetRepositoryImpl(this._api);

  @override
  Future<PagedResult<Asset>> getAssets() async {
    final json = await _api.get('/assets');
    return parseResponse(
      () => PagedResponseDto.fromJson(json as Map<String, dynamic>, AssetDto.fromJson)
          .toDomain((dto) => dto.toDomain()),
    );
  }

  @override
  Future<AssetDetail> getAssetDetail(String assetId) async {
    final json = await _api.get('/assets/$assetId');
    return parseResponse(
      () => AssetDetailDto.fromJson(json as Map<String, dynamic>).toDomain(),
    );
  }

  @override
  Future<List<SensorReading>> getSensors(String assetId) async {
    final json = await _api.get('/assets/$assetId/sensors');
    return parseResponse(
      () => (json as List)
          .map((e) => SensorReadingDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList(),
    );
  }

  AssetDetail _detail(dynamic json) => parseResponse(
        () => AssetDetailDto.fromJson(json as Map<String, dynamic>).toDomain(),
      );

  @override
  Future<AssetDetail> updateAsset(String assetId, AssetUpdate u) async =>
      _detail(await _api.put('/assets/$assetId', body: {
        'name': u.name,
        'location': u.location,
        'assetType': u.assetType,
        'criticality': apiName(u.criticality),
        'plantId': u.plantId,
        'productionLine': u.productionLine,
        'latitude': u.latitude,
        'longitude': u.longitude,
      }));

  @override
  Future<AssetDetail> deactivateAsset(String assetId, {bool force = false}) async =>
      _detail(await _api.delete('/assets/$assetId',
          query: {'force': force ? 'true' : null}));
}
