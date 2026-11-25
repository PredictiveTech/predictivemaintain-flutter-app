import '../domain/asset.dart';
import '../domain/asset_repository.dart';
import '../domain/paged_result.dart';

class GetAssetsUseCase {
  final AssetRepository _repository;

  GetAssetsUseCase(this._repository);

  Future<PagedResult<Asset>> call() => _repository.getAssets();
}
