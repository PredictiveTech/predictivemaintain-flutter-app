import '../domain/availability_report.dart';
import '../domain/report_range.dart';
import '../domain/report_repository.dart';

class GetAvailabilityReportUseCase {
  final ReportRepository _repository;
  final DateTime Function() _now;

  GetAvailabilityReportUseCase(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<AvailabilityReport> call(String assetId, ReportRange range) async =>
      _repository.getAvailability(assetId, range.validated(_now()));
}
