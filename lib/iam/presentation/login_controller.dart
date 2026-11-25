import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/failure.dart';
import '../../app/session_controller.dart';

/// Estado del envío del formulario de login: loading / error / data(null).
class LoginController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(loginUseCaseProvider)(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
      ref.read(sessionControllerProvider.notifier).signedIn(session);
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
    }
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(LoginController.new);

/// Texto mostrado al usuario cuando falla el login.
String loginErrorMessage(Failure failure) {
  if (failure is NetworkFailure || failure is MalformedResponseFailure) {
    return 'No se pudo iniciar sesión: ${failure.message}';
  }
  return failure.serverMessage ??
      'Error al iniciar sesión (${failure.message})';
}
