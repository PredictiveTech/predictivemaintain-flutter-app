import '../../core/error/failure.dart';
import '../domain/asset_detail.dart';
import '../domain/asset_repository.dart';
import '../domain/asset_update.dart';

/// Edita la ficha de un activo (US-12) validando los límites del backend.
class UpdateAssetUseCase {
  final AssetRepository _repository;

  UpdateAssetUseCase(this._repository);

  Future<AssetDetail> call(String assetId, AssetUpdate u) async {
    void require(String value, String field, int max) {
      if (value.trim().isEmpty) throw ValidationFailure('$field es obligatorio.');
      if (value.length > max) {
        throw ValidationFailure('$field no puede superar los $max caracteres.');
      }
    }

    require(u.name, 'El nombre', 120);
    require(u.location, 'La ubicación', 120);
    require(u.assetType, 'El tipo', 80);
    if ((u.productionLine?.length ?? 0) > 100) {
      throw const ValidationFailure('La línea de producción no puede superar los 100 caracteres.');
    }
    final lat = u.latitude, lon = u.longitude;
    if (lat != null && (lat < -90 || lat > 90)) {
      throw const ValidationFailure('La latitud debe estar entre -90 y 90.');
    }
    if (lon != null && (lon < -180 || lon > 180)) {
      throw const ValidationFailure('La longitud debe estar entre -180 y 180.');
    }
    return _repository.updateAsset(assetId, u);
  }
}
