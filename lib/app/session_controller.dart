import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'injection.dart';
import '../iam/domain/auth_session.dart';

/// Sesión activa de la app (null = sin sesión). El router observa este estado
/// para decidir entre login y home.
class SessionController extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => null;

  /// Carga la sesión guardada; se llama una vez al arrancar, antes de `runApp`.
  Future<void> restore() async {
    state = await ref.read(restoreSessionUseCaseProvider)();
  }

  void signedIn(AuthSession session) => state = session;

  /// El backend respondió 401 a una petición autenticada: cerrar sesión.
  /// Idempotente, porque varias peticiones en vuelo pueden fallar a la vez.
  Future<void> onUnauthorized() async {
    if (state == null) return;
    state = null;
    await ref.read(logoutUseCaseProvider)();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AuthSession?>(SessionController.new);
