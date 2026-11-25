import 'alert.dart';
import 'paged_result.dart';

abstract interface class AlertRepository {
  Future<PagedResult<Alert>> getAlerts();
}
