import 'severity.dart';
import 'work_order_status.dart';

/// Orden de trabajo devuelta por GET /api/v1/work-orders.
class WorkOrder {
  final String id;
  final String alertId;
  final String assetId;
  final String assetCode;
  final String assetName;
  final Severity severity;
  final String? assignedUserId;
  final WorkOrderStatus status;
  final String summary;
  final DateTime openedAt;
  final DateTime? completedAt;
  final int version;

  const WorkOrder({
    required this.id,
    required this.alertId,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.severity,
    required this.status,
    required this.summary,
    required this.openedAt,
    required this.version,
    this.assignedUserId,
    this.completedAt,
  });
}
