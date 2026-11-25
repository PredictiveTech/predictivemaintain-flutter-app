import '../domain/auth_session.dart';
import '../domain/auth_session_store.dart';

/// Recupera la sesión guardada; descarta (y borra) la que ya expiró.
class RestoreSessionUseCase {
  final AuthSessionStore _store;
  final DateTime Function() _now;

  RestoreSessionUseCase(this._store, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<AuthSession?> call() async {
    final session = await _store.read();
    if (session == null) return null;
    if (!session.expiresAt.isAfter(_now())) {
      await _store.clear();
      return null;
    }
    return session;
  }
}
