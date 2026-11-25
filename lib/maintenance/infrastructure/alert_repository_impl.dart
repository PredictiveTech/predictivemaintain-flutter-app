import '../../core/domain/paged_result.dart';
import '../../core/network/api_client.dart';
import '../domain/alert.dart';
import '../domain/alert_repository.dart';
import '../domain/alert_status.dart';
import '../domain/severity.dart';
import 'alert_dto.dart';
import 'enum_parser.dart';
import 'paged_response_dto.dart';

class AlertRepositoryImpl implements AlertRepository {
  final ApiClient _api;

  AlertRepositoryImpl(this._api);

  @override
  Future<PagedResult<Alert>> getAlerts({
    AlertStatus? status,
    Severity? severity,
    int page = 0,
  }) async {
    final json = await _api.get('/alerts', query: {
      'status': status == null ? null : apiName(status),
      'severity': severity == null ? null : apiName(severity),
      'page': page == 0 ? null : '$page',
    });
    return parseResponse(
      () => PagedResponseDto.fromJson(json as Map<String, dynamic>, AlertDto.fromJson)
          .toDomain((dto) => dto.toDomain()),
    );
  }

  @override
  Future<Alert> getAlert(String id) async {
    final json = await _api.get('/alerts/$id');
    return parseResponse(() => AlertDto.fromJson(json as Map<String, dynamic>).toDomain());
  }

  @override
  Future<Alert> updateStatus({
    required String id,
    required AlertStatus status,
    String? reason,
    int? expectedVersion,
  }) async {
    final json = await _api.patch('/alerts/$id/status', body: {
      'status': apiName(status),
      'reason': ?reason,
      'expectedVersion': ?expectedVersion,
    });
    return parseResponse(() => AlertDto.fromJson(json as Map<String, dynamic>).toDomain());
  }
}
