import '../domain/asset_repository.dart';
import '../domain/sensor_reading.dart';

class GetAssetSensorsUseCase {
  final AssetRepository _repository;

  GetAssetSensorsUseCase(this._repository);

  Future<List<SensorReading>> call(String assetId) => _repository.getSensors(assetId);
}
