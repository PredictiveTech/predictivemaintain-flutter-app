class SensorReading {
  final String id;
  final String metric;
  final String unit;
  final double latestReading;
  final String? threshold;
  final String rangeStatus;

  const SensorReading({
    required this.id,
    required this.metric,
    required this.unit,
    required this.latestReading,
    this.threshold,
    required this.rangeStatus,
  });
}
