import '../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_session_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;

  AuthRepositoryImpl(this._api);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return parseResponse(
      () => AuthSessionDto.fromJson(json as Map<String, dynamic>).toDomain(),
    );
  }
}
