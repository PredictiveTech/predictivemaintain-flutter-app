import 'alert.dart';
import 'alert_status.dart';
import 'paged_result.dart';
import 'severity.dart';

abstract interface class AlertRepository {
  Future<PagedResult<Alert>> getAlerts({
    AlertStatus? status,
    Severity? severity,
    int page = 0,
  });

  Future<Alert> getAlert(String id);

  /// Confirma o descarta. [reason] es obligatorio al descartar;
  /// [expectedVersion] provoca 409 si la alerta cambió.
  Future<Alert> updateStatus({
    required String id,
    required AlertStatus status,
    String? reason,
    int? expectedVersion,
  });
}
