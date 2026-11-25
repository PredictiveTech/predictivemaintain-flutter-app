import '../domain/auth_session_store.dart';

class LogoutUseCase {
  final AuthSessionStore _store;

  LogoutUseCase(this._store);

  Future<void> call() => _store.clear();
}
