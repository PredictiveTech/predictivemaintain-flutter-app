import '../domain/sensor_reading.dart';

class SensorReadingDto {
  final String id;
  final String metric;
  final String unit;
  final double latestReading;
  final String? threshold;
  final String rangeStatus;

  const SensorReadingDto({
    required this.id,
    required this.metric,
    required this.unit,
    required this.latestReading,
    this.threshold,
    required this.rangeStatus,
  });

  factory SensorReadingDto.fromJson(Map<String, dynamic> json) => SensorReadingDto(
        id: json['id'].toString(),
        metric: json['metric'] as String,
        unit: json['unit'] as String,
        latestReading: (json['latestReading'] as num).toDouble(),
        threshold: json['threshold']?.toString(),
        rangeStatus: json['rangeStatus'] as String,
      );

  SensorReading toDomain() => SensorReading(
        id: id,
        metric: metric,
        unit: unit,
        latestReading: latestReading,
        threshold: threshold,
        rangeStatus: rangeStatus,
      );
}
