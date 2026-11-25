import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/auth_session_store.dart';

/// Autentica y persiste la sesión resultante.
class LoginUseCase {
  final AuthRepository _repository;
  final AuthSessionStore _store;

  LoginUseCase(this._repository, this._store);

  Future<AuthSession> call({required String email, required String password}) async {
    final session = await _repository.login(email: email, password: password);
    await _store.save(session);
    return session;
  }
}
