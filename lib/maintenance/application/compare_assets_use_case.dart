import '../../core/error/failure.dart';
import '../domain/comparison_row.dart';
import '../domain/report_range.dart';
import '../domain/report_repository.dart';

/// Reporte comparativo (US-15): de 1 a 20 activos.
class CompareAssetsUseCase {
  static const maxAssets = 20;

  final ReportRepository _repository;
  final DateTime Function() _now;

  CompareAssetsUseCase(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<List<ComparisonRow>> call(List<String> assetIds, ReportRange range) async {
    if (assetIds.isEmpty) {
      throw const ValidationFailure('Selecciona al menos un activo.');
    }
    if (assetIds.length > maxAssets) {
      throw const ValidationFailure('Puedes comparar hasta 20 activos.');
    }
    return _repository.compare(assetIds, range.validated(_now()));
  }
}
