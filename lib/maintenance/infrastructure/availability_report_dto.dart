import '../domain/availability_report.dart';
import 'enum_parser.dart';

class AssetEventDto {
  final String type;
  final String referenceId;
  final String occurredAt;
  final String? endedAt;
  final String? severity;
  final String? status;

  const AssetEventDto({
    required this.type,
    required this.referenceId,
    required this.occurredAt,
    this.endedAt,
    this.severity,
    this.status,
  });

  factory AssetEventDto.fromJson(Map<String, dynamic> json) => AssetEventDto(
        type: json['type'] as String,
        referenceId: json['referenceId'].toString(),
        occurredAt: json['occurredAt'] as String,
        endedAt: json['endedAt'] as String?,
        severity: json['severity'] as String?,
        status: json['status'] as String?,
      );

  AssetEvent toDomain() => AssetEvent(
        type: parseEnum(AssetEventType.values, type),
        referenceId: referenceId,
        occurredAt: DateTime.parse(occurredAt),
        endedAt: endedAt == null ? null : DateTime.parse(endedAt!),
        severity: severity,
        status: status,
      );
}

class AvailabilityReportDto {
  final String assetId;
  final String assetCode;
  final String from;
  final String to;
  final double availabilityPercent;
  final int downtimeSeconds;
  final int periodSeconds;
  final bool hasEvents;
  final List<AssetEventDto> events;

  const AvailabilityReportDto({
    required this.assetId,
    required this.assetCode,
    required this.from,
    required this.to,
    required this.availabilityPercent,
    required this.downtimeSeconds,
    required this.periodSeconds,
    required this.hasEvents,
    required this.events,
  });

  factory AvailabilityReportDto.fromJson(Map<String, dynamic> json) =>
      AvailabilityReportDto(
        assetId: json['assetId'].toString(),
        assetCode: json['assetCode'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        availabilityPercent: (json['availabilityPercent'] as num).toDouble(),
        downtimeSeconds: (json['downtimeSeconds'] as num).toInt(),
        periodSeconds: (json['periodSeconds'] as num).toInt(),
        hasEvents: json['hasEvents'] as bool,
        events: (json['events'] as List)
            .map((e) => AssetEventDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  AvailabilityReport toDomain() => AvailabilityReport(
        assetId: assetId,
        assetCode: assetCode,
        from: DateTime.parse(from),
        to: DateTime.parse(to),
        availabilityPercent: availabilityPercent,
        downtime: Duration(seconds: downtimeSeconds),
        period: Duration(seconds: periodSeconds),
        hasEvents: hasEvents,
        events: events.map((e) => e.toDomain()).toList(),
      );
}
