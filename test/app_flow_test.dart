import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/app/injection.dart';
import 'package:predictivemaintain_flutter_app/app/session_controller.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/auth_repository.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/auth_session.dart';
import 'package:predictivemaintain_flutter_app/main.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_detail.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_repository.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/criticality.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/paged_result.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/sensor_reading.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_repository.dart';

import 'support/in_memory_session_store.dart';

class FakeAuth implements AuthRepository {
  Failure? failure;
  @override
  Future<AuthSession> login({required String email, required String password}) async {
    if (failure != null) throw failure!;
    return AuthSession(
      accessToken: 't',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      userId: '1',
      tenantId: '1',
      roles: const [],
    );
  }
}

PagedResult<T> page<T>(List<T> items) => PagedResult(
    items: items, number: 0, size: 20, totalElements: items.length, totalPages: 1);

class FakeAssets implements AssetRepository {
  Failure? detailFailure;

  @override
  Future<PagedResult<Asset>> getAssets() async => page([
        const Asset(
          id: '7',
          code: 'P-01',
          name: 'Bomba 1',
          location: 'Planta A',
          assetType: 'PUMP',
          criticality: Criticality.high,
          active: true,
          status: AssetStatus.inAlert,
          sensorTypes: [],
        ),
      ]);

  @override
  Future<AssetDetail> getAssetDetail(String id) async {
    if (detailFailure != null) throw detailFailure!;
    return AssetDetail(
      id: id,
      code: 'P-01',
      name: 'Bomba 1 detalle',
      location: 'Planta A',
      plantId: '1',
      assetType: 'PUMP',
      criticality: Criticality.high,
      active: true,
    );
  }

  @override
  Future<List<SensorReading>> getSensors(String id) async => const [];
}

class FakeAlerts implements AlertRepository {
  @override
  Future<PagedResult<Alert>> getAlerts() async => page(<Alert>[]);
}

class FakeOrders implements WorkOrderRepository {
  @override
  Future<PagedResult<WorkOrder>> getWorkOrders() async => page(<WorkOrder>[]);
}

void main() {
  late FakeAuth auth;
  late FakeAssets assets;
  late InMemorySessionStore store;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(auth),
        assetRepositoryProvider.overrideWithValue(assets),
        alertRepositoryProvider.overrideWithValue(FakeAlerts()),
        workOrderRepositoryProvider.overrideWithValue(FakeOrders()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'a@b.c');
    await tester.enterText(find.byType(TextField).last, 'pw');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    auth = FakeAuth();
    assets = FakeAssets();
    store = InMemorySessionStore();
  });

  testWidgets('login lleva a home, persiste la sesión y abre el detalle', (tester) async {
    await pumpApp(tester);
    await login(tester);

    expect(find.text('Bomba 1'), findsOneWidget);
    expect(store.session?.accessToken, 't');

    await tester.tap(find.text('Bomba 1'));
    await tester.pumpAndSettle();
    expect(find.text('Bomba 1 detalle'), findsWidgets);
    expect(find.text('Alerta'), findsWidgets); // status pasado como extra
    expect(find.text('No hay sensores registrados para este activo'), findsOneWidget);
  });

  testWidgets('login fallido muestra el mensaje del servidor y no navega', (tester) async {
    auth.failure = const UnauthorizedFailure('HTTP 401', serverMessage: 'Credenciales inválidas');
    await pumpApp(tester);
    await login(tester);

    expect(find.text('Credenciales inválidas'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('con sesión guardada arranca directo en home', (tester) async {
    store = InMemorySessionStore(await FakeAuth().login(email: '', password: ''));
    final container = ProviderContainer(overrides: [
      authSessionStoreProvider.overrideWithValue(store),
      assetRepositoryProvider.overrideWithValue(assets),
      alertRepositoryProvider.overrideWithValue(FakeAlerts()),
      workOrderRepositoryProvider.overrideWithValue(FakeOrders()),
    ]);
    addTearDown(container.dispose);
    // Mismo paso que main(): restaurar antes de montar la app.
    await container.read(sessionControllerProvider.notifier).restore();
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bomba 1'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('un 401 en el detalle cierra sesión y vuelve a login', (tester) async {
    await pumpApp(tester);
    await login(tester);
    await tester.tap(find.text('Bomba 1'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));
    await container.read(sessionControllerProvider.notifier).onUnauthorized();
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(store.session, isNull);
  });
}
