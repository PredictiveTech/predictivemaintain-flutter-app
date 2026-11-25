import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:predictivemaintain_flutter_app/app/injection.dart';
import 'package:predictivemaintain_flutter_app/main.dart';

import 'support/in_memory_session_store.dart';

void main() {
  testWidgets('La app inicia en la pantalla de login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // flutter_secure_storage no existe en el entorno de test.
        overrides: [authSessionStoreProvider.overrideWithValue(InMemorySessionStore())],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
