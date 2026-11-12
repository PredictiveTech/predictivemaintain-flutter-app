import 'alert_diagnostic.dart';
import 'alert_status.dart';
import 'severity.dart';

/// Alerta devuelta por GET /api/v1/alerts.
class Alert {
  final String id;
  final String assetId;
  final String assetCode;
  final String assetName;
  final Severity severity;
  final AlertStatus status;
  final DateTime raisedAt;
  final String? discardReason;
  final int version;
  final AlertDiagnostic? diagnostic;

  const Alert({
    required this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.severity,
    required this.status,
    required this.raisedAt,
    required this.version,
    this.discardReason,
    this.diagnostic,
  });
}
