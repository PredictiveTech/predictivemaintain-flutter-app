import '../domain/severity.dart';
import '../domain/work_order.dart';
import '../domain/work_order_status.dart';
import 'enum_parser.dart';

class WorkOrderDto {
  final String id;
  final String alertId;
  final String assetId;
  final String assetCode;
  final String assetName;
  final String severity;
  final String? assignedUserId;
  final String status;
  final String summary;
  final String openedAt;
  final String? completedAt;
  final int version;

  const WorkOrderDto({
    required this.id,
    required this.alertId,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.severity,
    required this.assignedUserId,
    required this.status,
    required this.summary,
    required this.openedAt,
    required this.completedAt,
    required this.version,
  });

  factory WorkOrderDto.fromJson(Map<String, dynamic> json) => WorkOrderDto(
        id: json['id'].toString(),
        alertId: json['alertId'].toString(),
        assetId: json['assetId'].toString(),
        assetCode: json['assetCode'] as String,
        assetName: json['assetName'] as String,
        severity: json['severity'] as String,
        assignedUserId: json['assignedUserId']?.toString(),
        status: json['status'] as String,
        summary: json['summary'] as String,
        openedAt: json['openedAt'] as String,
        completedAt: json['completedAt'] as String?,
        version: (json['version'] as num).toInt(),
      );

  WorkOrder toDomain() => WorkOrder(
        id: id,
        alertId: alertId,
        assetId: assetId,
        assetCode: assetCode,
        assetName: assetName,
        severity: parseEnum(Severity.values, severity),
        assignedUserId: assignedUserId,
        status: parseEnum(WorkOrderStatus.values, status),
        summary: summary,
        openedAt: DateTime.parse(openedAt),
        completedAt: completedAt == null ? null : DateTime.parse(completedAt!),
        version: version,
      );
}
