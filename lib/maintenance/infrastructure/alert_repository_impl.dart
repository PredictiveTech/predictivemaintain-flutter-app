import '../../core/network/api_client.dart';
import '../domain/alert.dart';
import '../domain/alert_repository.dart';
import '../domain/paged_result.dart';
import 'alert_dto.dart';
import 'paged_response_dto.dart';

class AlertRepositoryImpl implements AlertRepository {
  final ApiClient _api;

  AlertRepositoryImpl(this._api);

  @override
  Future<PagedResult<Alert>> getAlerts() async {
    final json = await _api.get('/alerts');
    return parseResponse(
      () => PagedResponseDto.fromJson(json as Map<String, dynamic>, AlertDto.fromJson)
          .toDomain((dto) => dto.toDomain()),
    );
  }
}
