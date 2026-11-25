import 'auth_session.dart';

/// Almacén persistente de la sesión activa.
abstract interface class AuthSessionStore {
  Future<AuthSession?> read();
  Future<void> save(AuthSession session);
  Future<void> clear();
}
