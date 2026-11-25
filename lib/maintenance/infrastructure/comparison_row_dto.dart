import '../domain/comparison_row.dart';

class ComparisonRowDto {
  final String assetId;
  final String assetCode;
  final String assetName;
  final int alerts;
  final int criticalAlerts;
  final int stops;
  final int downtimeSeconds;
  final double availabilityPercent;

  const ComparisonRowDto({
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.alerts,
    required this.criticalAlerts,
    required this.stops,
    required this.downtimeSeconds,
    required this.availabilityPercent,
  });

  factory ComparisonRowDto.fromJson(Map<String, dynamic> json) => ComparisonRowDto(
        assetId: json['assetId'].toString(),
        assetCode: json['assetCode'] as String,
        assetName: json['assetName'] as String,
        alerts: (json['alerts'] as num).toInt(),
        criticalAlerts: (json['criticalAlerts'] as num).toInt(),
        stops: (json['stops'] as num).toInt(),
        downtimeSeconds: (json['downtimeSeconds'] as num).toInt(),
        availabilityPercent: (json['availabilityPercent'] as num).toDouble(),
      );

  ComparisonRow toDomain() => ComparisonRow(
        assetId: assetId,
        assetCode: assetCode,
        assetName: assetName,
        alerts: alerts,
        criticalAlerts: criticalAlerts,
        stops: stops,
        downtime: Duration(seconds: downtimeSeconds),
        availabilityPercent: availabilityPercent,
      );
}
