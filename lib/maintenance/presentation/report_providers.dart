import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/failure.dart';
import '../../core/error/retry.dart';
import '../domain/availability_report.dart';
import '../domain/comparison_row.dart';
import '../domain/report_range.dart';

typedef AvailabilityQuery = ({String assetId, ReportRange range});

final availabilityReportProvider =
    FutureProvider.autoDispose.family<AvailabilityReport, AvailabilityQuery>(
  (ref, q) => ref.watch(getAvailabilityReportUseCaseProvider)(q.assetId, q.range),
  retry: noRetry,
);

/// Resultado del reporte comparativo. `null` = todavía no se generó.
class ComparisonController extends AsyncNotifier<List<ComparisonRow>?> {
  @override
  List<ComparisonRow>? build() => null;

  Future<void> generate(List<String> assetIds, ReportRange range) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await ref.read(compareAssetsUseCaseProvider)(assetIds, range));
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
    }
  }
}

final comparisonProvider =
    AsyncNotifierProvider.autoDispose<ComparisonController, List<ComparisonRow>?>(
        ComparisonController.new);

/// Exportación a CSV. El estado guarda el nombre del archivo generado.
class ExportController extends AsyncNotifier<String?> {
  @override
  String? build() => null;

  Future<void> export(List<String> assetIds, ReportRange range) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await ref.read(exportHistoryUseCaseProvider)(assetIds, range));
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
    } catch (e, st) {
      // Error de plataforma al guardar o compartir el archivo.
      state = AsyncError(e, st);
    }
  }
}

final exportProvider =
    AsyncNotifierProvider.autoDispose<ExportController, String?>(ExportController.new);
