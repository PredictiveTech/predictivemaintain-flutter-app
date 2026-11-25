/// Una fila de GET /api/v1/reports/comparison.
class ComparisonRow {
  final String assetId;
  final String assetCode;
  final String assetName;
  final int alerts;
  final int criticalAlerts;
  final int stops;
  final Duration downtime;
  final double availabilityPercent;

  const ComparisonRow({
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.alerts,
    required this.criticalAlerts,
    required this.stops,
    required this.downtime,
    required this.availabilityPercent,
  });
}
