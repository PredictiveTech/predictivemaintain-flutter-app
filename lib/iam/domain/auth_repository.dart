import 'auth_session.dart';

abstract interface class AuthRepository {
  /// Autentica con email y contraseña. Lanza un `Failure` si falla.
  Future<AuthSession> login({required String email, required String password});
}
