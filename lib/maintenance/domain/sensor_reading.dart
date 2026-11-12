import 'severity.dart';

/// ONLINE / NO_COMMUNICATION (sin lecturas hace más de 5 min, o nunca).
enum CommunicationStatus { online, noCommunication }

/// UNKNOWN: no hay lectura o no hay umbral para comparar.
enum RangeStatus { normal, outOfRange, unknown }

class LatestReading {
  final double value;
  final DateTime measuredAt;

  const LatestReading({required this.value, required this.measuredAt});
}

class SensorThreshold {
  final double lowerBound;
  final double upperBound;
  final Severity severity;
  final int version;

  const SensorThreshold({
    required this.lowerBound,
    required this.upperBound,
    required this.severity,
    required this.version,
  });
}

/// Un elemento del panel de sensores (GET /api/v1/assets/{id}/sensors).
class SensorReading {
  final String id;
  final String metric;
  final String unit;
  final bool active;
  final CommunicationStatus communication;
  final DateTime? lastReceivedAt;
  final LatestReading? latestReading;
  final SensorThreshold? threshold;
  final RangeStatus rangeStatus;

  const SensorReading({
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
}
