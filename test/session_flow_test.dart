import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/app/injection.dart';
import 'package:predictivemaintain_flutter_app/app/session_controller.dart';
import 'package:predictivemaintain_flutter_app/iam/application/restore_session_use_case.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/auth_session.dart';

import 'support/in_memory_session_store.dart';

AuthSession sessionExpiring(DateTime at) => AuthSession(
      accessToken: 't',
      tokenType: 'Bearer',
      expiresAt: at,
      userId: '1',
      tenantId: '1',
      roles: const ['MAINTENANCE_MANAGER'],
    );

void main() {
  test('restaura una sesión vigente', () async {
    final s = sessionExpiring(DateTime.now().add(const Duration(hours: 1)));
    expect(await RestoreSessionUseCase(InMemorySessionStore(s))(), s);
  });

  test('descarta y borra una sesión expirada', () async {
    final store = InMemorySessionStore(
        sessionExpiring(DateTime.now().subtract(const Duration(minutes: 1))));
    expect(await RestoreSessionUseCase(store)(), isNull);
    expect(store.session, isNull);
  });

  test('onUnauthorized cierra sesión y limpia el almacén (idempotente)', () async {
    final store = InMemorySessionStore(
        sessionExpiring(DateTime.now().add(const Duration(hours: 1))));
    final container = ProviderContainer(
      overrides: [authSessionStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final controller = container.read(sessionControllerProvider.notifier);
    await controller.restore();
    expect(container.read(sessionControllerProvider), isNotNull);

    await controller.onUnauthorized();
    await controller.onUnauthorized();

    expect(container.read(sessionControllerProvider), isNull);
    expect(store.session, isNull);
  });
}
