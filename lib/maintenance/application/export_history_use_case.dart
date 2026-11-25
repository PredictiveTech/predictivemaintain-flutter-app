import '../../core/domain/file_exporter.dart';
import '../../core/error/failure.dart';
import '../domain/report_range.dart';
import '../domain/report_repository.dart';

/// Descarga el historial en CSV (US-16) y lo entrega al usuario (guardar y
/// abrir la hoja de compartir).
class ExportHistoryUseCase {
  final ReportRepository _repository;
  final FileExporter _exporter;
  final DateTime Function() _now;

  ExportHistoryUseCase(this._repository, this._exporter, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<String> call(List<String> assetIds, ReportRange range) async {
    if (assetIds.isEmpty) {
      throw const ValidationFailure('Selecciona al menos un activo.');
    }
    final valid = range.validated(_now());
    final bytes = await _repository.exportHistory(assetIds, valid);
    final fileName = 'historial_mantenimiento_${_day(valid.from)}_${_day(valid.to)}.csv';
    await _exporter.saveAndShare(fileName: fileName, bytes: bytes, mimeType: 'text/csv');
    return fileName;
  }

  static String _day(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}${two(l.month)}${two(l.day)}';
  }
}
