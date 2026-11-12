import '../domain/sensor_reading.dart';
import '../domain/severity.dart';
import 'enum_parser.dart';

/// Un elemento de SensorPanelItemResource del backend.
class SensorReadingDto {
  final String id;
  final String metric;
  final String unit;
  final bool active;
  final String communication;
  final String? lastReceivedAt;
  final Map<String, dynamic>? latestReading;
  final Map<String, dynamic>? threshold;
  final String rangeStatus;

  const SensorReadingDto({
    required this.id,
    required this.metric,
    required this.unit,
    required this.active,
    required this.communication,
    this.lastReceivedAt,
    this.latestReading,
    this.threshold,
    required this.rangeStatus,
  });

  factory SensorReadingDto.fromJson(Map<String, dynamic> json) => SensorReadingDto(
        id: json['id'].toString(),
        metric: json['metric'] as String,
        unit: json['unit'] as String,
        active: json['active'] as bool,
        communication: json['communication'] as String,
        lastReceivedAt: json['lastReceivedAt'] as String?,
        latestReading: json['latestReading'] as Map<String, dynamic>?,
        threshold: json['threshold'] as Map<String, dynamic>?,
        rangeStatus: json['rangeStatus'] as String,
      );

  SensorReading toDomain() {
    final reading = latestReading;
    final thr = threshold;
    return SensorReading(
      id: id,
      metric: metric,
      unit: unit,
      active: active,
      communication: parseEnum(CommunicationStatus.values, communication),
      lastReceivedAt: lastReceivedAt == null ? null : DateTime.parse(lastReceivedAt!),
      latestReading: reading == null
          ? null
          : LatestReading(
              value: (reading['value'] as num).toDouble(),
              measuredAt: DateTime.parse(reading['measuredAt'] as String),
            ),
      threshold: thr == null
          ? null
          : SensorThreshold(
              lowerBound: (thr['lowerBound'] as num).toDouble(),
              upperBound: (thr['upperBound'] as num).toDouble(),
              severity: parseEnum(Severity.values, thr['severity']),
              version: (thr['version'] as num).toInt(),
            ),
      rangeStatus: parseEnum(RangeStatus.values, rangeStatus),
    );
  }
}
