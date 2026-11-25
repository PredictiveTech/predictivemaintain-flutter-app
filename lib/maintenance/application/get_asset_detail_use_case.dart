import '../domain/asset_detail.dart';
import '../domain/asset_repository.dart';

class GetAssetDetailUseCase {
  final AssetRepository _repository;

  GetAssetDetailUseCase(this._repository);

  Future<AssetDetail> call(String assetId) => _repository.getAssetDetail(assetId);
}
