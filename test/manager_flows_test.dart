import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/app/injection.dart';
import 'package:predictivemaintain_flutter_app/app/router.dart';
import 'package:predictivemaintain_flutter_app/app/session_controller.dart';
import 'package:predictivemaintain_flutter_app/core/domain/paged_result.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/auth_session.dart';
import 'package:predictivemaintain_flutter_app/main.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/severity.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_status.dart';

import 'support/fakes.dart';
import 'support/in_memory_session_store.dart';

class PagingAlerts extends FakeAlertRepository {
  PagingAlerts() : super([]);

  @override
  Future<PagedResult<Alert>> getAlerts({AlertStatus? status, Severity? severity, int page = 0}) async {
    calls.add('page=$page status=$status severity=$severity');
    return pagedOf(
      [makeAlert(id: 'p$page').copyName('Activo página $page')],
      number: page,
      totalPages: 2,
    );
  }
}

extension on Alert {
  Alert copyName(String name) => Alert(
        id: id,
        assetId: assetId,
        assetCode: assetCode,
        assetName: name,
        severity: severity,
        status: status,
        raisedAt: raisedAt,
        version: version,
        diagnostic: diagnostic,
      );
}

void main() {
  late FakeAlertRepository alerts;
  late FakeWorkOrderRepository orders;
  late FakeUserRepository users;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester) async {
    final session = AuthSession(
        accessToken: 't',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: '1',
        tenantId: '1',
        roles: const ['MAINTENANCE_MANAGER']);
    container = ProviderContainer(overrides: [
      authSessionStoreProvider.overrideWithValue(InMemorySessionStore(session)),
      alertRepositoryProvider.overrideWithValue(alerts),
      workOrderRepositoryProvider.overrideWithValue(orders),
      userRepositoryProvider.overrideWithValue(users),
      assetRepositoryProvider.overrideWithValue(FakeAssetRepository()),
    ]);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String location) async {
    container.read(routerProvider).push(location);
    await tester.pumpAndSettle();
  }

  setUp(() {
    alerts = FakeAlertRepository([makeAlert(), makeAlert(id: 'a2', status: AlertStatus.confirmed)]);
    orders = FakeWorkOrderRepository([makeOrder()]);
    users = FakeUserRepository([
      [makeUser('u1', 'Ana Técnica'), makeUser('u2', 'Beto Técnico')],
    ]);
  });

  group('alerta', () {
    testWidgets('muestra métrica, valor observado contra límites y fecha', (tester) async {
      await pumpApp(tester);
      await open(tester, '/alerts/a1');
      expect(find.text('Métrica: TEMPERATURE'), findsOneWidget);
      expect(find.text('Valor observado: 101.25 °C'), findsOneWidget);
      expect(find.text('Rango permitido: 20 – 85 °C'), findsOneWidget);
      expect(find.textContaining('Medido:'), findsOneWidget);
    });

    testWidgets('descartar exige motivo y lo envía', (tester) async {
      await pumpApp(tester);
      await open(tester, '/alerts/a1');
      await tester.tap(find.text('Descartar alerta'));
      await tester.pumpAndSettle();

      final confirm = find.widgetWithText(FilledButton, 'Descartar');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull); // sin motivo

      await tester.enterText(find.byType(TextField), 'Sensor descalibrado');
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(alerts.lastUpdate!['status'], AlertStatus.discarded);
      expect(alerts.lastUpdate!['reason'], 'Sensor descalibrado');
      expect(alerts.lastUpdate!['expectedVersion'], 3);
    });

    testWidgets('generar orden está deshabilitado hasta confirmar', (tester) async {
      await pumpApp(tester);
      await open(tester, '/alerts/a1');
      FilledButton gen() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Generar orden de trabajo'));
      expect(gen().onPressed, isNull);

      await tester.tap(find.text('Confirmar alerta'));
      await tester.pumpAndSettle();
      expect(alerts.lastUpdate!['status'], AlertStatus.confirmed);
      expect(gen().onPressed, isNotNull); // el detalle se recargó ya confirmado
    });

    testWidgets('generar orden desde alerta confirmada abre el detalle de la orden', (tester) async {
      await pumpApp(tester);
      await open(tester, '/alerts/a2');
      await tester.tap(find.widgetWithText(FilledButton, 'Generar orden de trabajo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Generar'));
      await tester.pumpAndSettle();

      expect(orders.last, {'op': 'create', 'alertId': 'a2'});
      expect(find.text('Orden de trabajo'), findsOneWidget); // título del detalle
    });

    testWidgets('un 409 al confirmar ofrece recargar', (tester) async {
      await pumpApp(tester);
      await open(tester, '/alerts/a1');
      alerts.failure = const ConflictFailure('HTTP 409');
      await tester.tap(find.text('Confirmar alerta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('La alerta cambió'), findsOneWidget);
      expect(find.text('Recargar'), findsOneWidget);
    });
  });

  group('orden de trabajo', () {
    testWidgets('asignar: lista técnicos y envía técnico + versión', (tester) async {
      await pumpApp(tester);
      await open(tester, '/work-orders/w1');
      expect(find.text('Sin asignar'), findsOneWidget);

      await tester.tap(find.text('Asignar técnico'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Técnica'), findsOneWidget);
      await tester.tap(find.text('Beto Técnico'));
      await tester.pumpAndSettle();

      expect(orders.last, {'op': 'assign', 'id': 'w1', 'technicianId': 'u2', 'expectedVersion': 5});
      expect(find.text('Beto Técnico'), findsOneWidget); // nombre resuelto
      expect(find.text('Reasignar técnico'), findsOneWidget);
    });

    testWidgets('409 al asignar muestra aviso con Recargar', (tester) async {
      await pumpApp(tester);
      await open(tester, '/work-orders/w1');
      orders.failure = const ConflictFailure('HTTP 409');
      await tester.tap(find.text('Asignar técnico'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Técnica'));
      await tester.pumpAndSettle();

      expect(find.textContaining('La orden cambió'), findsOneWidget);
      orders.failure = null;
      orders.orders = [makeOrder(status: WorkOrderStatus.assigned, assignedUserId: 'u1', version: 6)];
      await tester.tap(find.text('Recargar'));
      await tester.pumpAndSettle();
      expect(find.text('Reasignar técnico'), findsOneWidget);
    });

    testWidgets('cancelar envía CANCELLED con motivo y versión', (tester) async {
      await pumpApp(tester);
      await open(tester, '/work-orders/w1');
      await tester.tap(find.text('Cancelar orden'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Falsa alarma');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar orden'));
      await tester.pumpAndSettle();
      expect(orders.last!['status'], WorkOrderStatus.cancelled);
      expect(orders.last!['summary'], 'Falsa alarma');
      expect(orders.last!['expectedVersion'], 5);
    });

    testWidgets('orden en progreso no permite asignar ni cancelar', (tester) async {
      orders = FakeWorkOrderRepository([makeOrder(status: WorkOrderStatus.inProgress, assignedUserId: 'u1')]);
      await pumpApp(tester);
      await open(tester, '/work-orders/w1');
      expect(find.text('Reasignar técnico'), findsNothing);
      expect(find.text('Cancelar orden'), findsNothing);
    });
  });

  group('listas', () {
    testWidgets('paginación: "Cargar más" anexa la página siguiente', (tester) async {
      alerts = PagingAlerts();
      await pumpApp(tester);
      await tester.tap(find.text('Alertas'));
      await tester.pumpAndSettle();

      expect(find.text('Activo página 0'), findsOneWidget);
      await tester.tap(find.text('Cargar más'));
      await tester.pumpAndSettle();
      expect(find.text('Activo página 0'), findsOneWidget);
      expect(find.text('Activo página 1'), findsOneWidget);
      expect(find.text('Cargar más'), findsNothing); // última página
      expect(alerts.calls, ['page=0 status=null severity=null', 'page=1 status=null severity=null']);
    });

    testWidgets('chip de severidad recarga desde la página 0 con el filtro', (tester) async {
      alerts = PagingAlerts();
      await pumpApp(tester);
      await tester.tap(find.text('Alertas'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Crítica'));
      await tester.pumpAndSettle();
      expect(alerts.calls.last, 'page=0 status=null severity=Severity.critical');
    });

    testWidgets('órdenes: filtro de estado se envía al backend; severidad filtra localmente', (tester) async {
      orders = FakeWorkOrderRepository([
        makeOrder(id: 'w1', severity: Severity.critical),
        makeOrder(id: 'w2', severity: Severity.warning, status: WorkOrderStatus.assigned),
      ]);
      await pumpApp(tester);
      await tester.tap(find.text('Órdenes de trabajo').last);
      await tester.pumpAndSettle();
      expect(find.text('Compresor 3'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Advertencia'));
      await tester.pumpAndSettle();
      expect(find.text('Compresor 3'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Asignada'));
      await tester.pumpAndSettle();
      expect(find.text('Compresor 3'), findsOneWidget);
    });
  });
}
