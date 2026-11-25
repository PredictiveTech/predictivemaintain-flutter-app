import 'dart:typed_data';

import 'availability_report.dart';
import 'comparison_row.dart';
import 'report_range.dart';

abstract interface class ReportRepository {
  Future<AvailabilityReport> getAvailability(String assetId, ReportRange range);
  Future<List<ComparisonRow>> compare(List<String> assetIds, ReportRange range);

  /// CSV con alertas y paros. Si no hay nada que exportar el backend
  /// responde 404 con un mensaje explicativo.
  Future<Uint8List> exportHistory(List<String> assetIds, ReportRange range);
}
