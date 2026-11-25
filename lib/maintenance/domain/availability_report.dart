enum AssetEventType { alert, downtime }

/// Alerta o paro de un activo dentro del rango del reporte.
class AssetEvent {
  final AssetEventType type;
  final String referenceId;
  final DateTime occurredAt;

  /// Fin del paro; null si sigue en curso (y siempre null en alertas).
  final DateTime? endedAt;
  final String? severity;
  final String? status;

  const AssetEvent({
    required this.type,
    required this.referenceId,
    required this.occurredAt,
    this.endedAt,
    this.severity,
    this.status,
  });
}

/// GET /api/v1/reports/availability.
class AvailabilityReport {
  final String assetId;
  final String assetCode;
  final DateTime from;
  final DateTime to;
  final double availabilityPercent;
  final Duration downtime;
  final Duration period;
  final bool hasEvents;
  final List<AssetEvent> events;

  const AvailabilityReport({
    required this.assetId,
    required this.assetCode,
    required this.from,
    required this.to,
    required this.availabilityPercent,
    required this.downtime,
    required this.period,
    required this.hasEvents,
    required this.events,
  });

  List<AssetEvent> get downtimes =>
      events.where((e) => e.type == AssetEventType.downtime).toList();
}
