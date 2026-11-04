import '../domain/alert_diagnostic.dart';

class AlertDiagnosticDto {
  final String metric;
  final String unit;
  final double observedValue;
  final double lowerBound;
  final double upperBound;
  final String measuredAt;

  const AlertDiagnosticDto({
    required this.metric,
    required this.unit,
    required this.observedValue,
    required this.lowerBound,
    required this.upperBound,
    required this.measuredAt,
  });

  factory AlertDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      AlertDiagnosticDto(
        metric: json['metric'] as String,
        unit: json['unit'] as String,
        observedValue: (json['observedValue'] as num).toDouble(),
        lowerBound: (json['lowerBound'] as num).toDouble(),
        upperBound: (json['upperBound'] as num).toDouble(),
        measuredAt: json['measuredAt'] as String,
      );

  AlertDiagnostic toDomain() => AlertDiagnostic(
        metric: metric,
        unit: unit,
        observedValue: observedValue,
        lowerBound: lowerBound,
        upperBound: upperBound,
        measuredAt: DateTime.parse(measuredAt),
      );
}
