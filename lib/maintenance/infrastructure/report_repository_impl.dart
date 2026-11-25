import 'dart:typed_data';

import '../../core/network/api_client.dart';
import '../domain/availability_report.dart';
import '../domain/comparison_row.dart';
import '../domain/report_range.dart';
import '../domain/report_repository.dart';
import 'availability_report_dto.dart';
import 'comparison_row_dto.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ApiClient _api;

  ReportRepositoryImpl(this._api);

  // date-time ISO-8601 en UTC; los ids de varios activos van separados por coma.
  Map<String, String?> _query(ReportRange r) => {
        'from': r.from.toUtc().toIso8601String(),
        'to': r.to.toUtc().toIso8601String(),
      };

  @override
  Future<AvailabilityReport> getAvailability(String assetId, ReportRange range) async {
    final json = await _api.get('/reports/availability', query: {
      'assetId': assetId,
      ..._query(range),
    });
    return parseResponse(
      () => AvailabilityReportDto.fromJson(json as Map<String, dynamic>).toDomain(),
    );
  }

  @override
  Future<List<ComparisonRow>> compare(List<String> assetIds, ReportRange range) async {
    final json = await _api.get('/reports/comparison', query: {
      'assetIds': assetIds.join(','),
      ..._query(range),
    });
    return parseResponse(
      () => (json as List)
          .map((e) => ComparisonRowDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList(),
    );
  }

  @override
  Future<Uint8List> exportHistory(List<String> assetIds, ReportRange range) =>
      _api.getBytes('/reports/history/export',
          query: {'assetIds': assetIds.join(','), ..._query(range)}, accept: 'text/csv');
}
