import '../domain/alert.dart';
import '../domain/alert_status.dart';
import '../domain/severity.dart';
import 'enum_parser.dart';

class AlertDto {
  final String id;
  final String assetId;
  final String assetCode;
  final String assetName;
  final String severity;
  final String status;
  final String raisedAt;
  final String? discardReason;
  final int version;
  final String? diagnostic;

  const AlertDto({
    required this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.severity,
    required this.status,
    required this.raisedAt,
    required this.discardReason,
    required this.version,
    required this.diagnostic,
  });

  factory AlertDto.fromJson(Map<String, dynamic> json) => AlertDto(
        id: json['id'].toString(),
        assetId: json['assetId'].toString(),
        assetCode: json['assetCode'] as String,
        assetName: json['assetName'] as String,
        severity: json['severity'] as String,
        status: json['status'] as String,
        raisedAt: json['raisedAt'] as String,
        discardReason: json['discardReason'] as String?,
        version: (json['version'] as num).toInt(),
        diagnostic: json['diagnostic'] as String?,
      );

  Alert toDomain() => Alert(
        id: id,
        assetId: assetId,
        assetCode: assetCode,
        assetName: assetName,
        severity: parseEnum(Severity.values, severity),
        status: parseEnum(AlertStatus.values, status),
        raisedAt: DateTime.parse(raisedAt),
        discardReason: discardReason,
        version: version,
        diagnostic: diagnostic,
      );
}
