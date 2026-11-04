import 'package:flutter_test/flutter_test.dart';

import 'package:predictivemaintain_flutter_app/main.dart';

void main() {
  testWidgets('La app inicia en la pantalla de login', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
