/// Medición que originó una alerta.
class AlertDiagnostic {
  final String metric;
  final String unit;
  final double observedValue;
  final double lowerBound;
  final double upperBound;
  final DateTime measuredAt;

  const AlertDiagnostic({
    required this.metric,
    required this.unit,
    required this.observedValue,
    required this.lowerBound,
    required this.upperBound,
    required this.measuredAt,
  });
}
