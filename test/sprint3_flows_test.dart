import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/app/injection.dart';
import 'package:predictivemaintain_flutter_app/app/router.dart';
import 'package:predictivemaintain_flutter_app/app/session_controller.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/auth_session.dart';
import 'package:predictivemaintain_flutter_app/main.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/availability_report.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/comparison_row.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_status.dart';

import 'support/fakes.dart';
import 'support/in_memory_session_store.dart';

void main() {
  late FakeAssetRepository assets;
  late FakeWorkOrderRepository orders;
  late FakeReportRepository reports;
  late FakeFileExporter exporter;
  late FakeSubscriptionRepository subscriptions;
  late FakeUserRepository users;
  late InMemorySessionStore store;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester, {List<String> roles = const ['MAINTENANCE_MANAGER']}) async {
    // Pantalla alta: el formulario de edición entra completo sin hacer scroll.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store = InMemorySessionStore(AuthSession(
        accessToken: 't',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: '1',
        tenantId: '1',
        roles: roles));
    container = ProviderContainer(overrides: [
      authSessionStoreProvider.overrideWithValue(store),
      assetRepositoryProvider.overrideWithValue(assets),
      workOrderRepositoryProvider.overrideWithValue(orders),
      alertRepositoryProvider.overrideWithValue(FakeAlertRepository()),
      reportRepositoryProvider.overrideWithValue(reports),
      fileExporterProvider.overrideWithValue(exporter),
      subscriptionRepositoryProvider.overrideWithValue(subscriptions),
      userRepositoryProvider.overrideWithValue(users),
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
    assets = FakeAssetRepository();
    orders = FakeWorkOrderRepository([
      makeOrder(id: 'o1'),
      makeOrder(id: 'o2', status: WorkOrderStatus.assigned),
    ]);
    reports = FakeReportRepository();
    exporter = FakeFileExporter();
    subscriptions = FakeSubscriptionRepository();
    users = FakeUserRepository([[]]);
  });

  group('navegación por rol', () {
    testWidgets('gerente: cinco pestañas incluida Suscripción', (tester) async {
      await pumpApp(tester);
      for (final label in ['Activos', 'Alertas', 'Órdenes de trabajo', 'Suscripción', 'Perfil']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      expect(find.byType(BottomNavigationBarItem), findsNothing); // son datos, no widgets
      final bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bar.items, hasLength(5));
    });

    testWidgets('otros roles no ven Suscripción', (tester) async {
      await pumpApp(tester, roles: const ['TECHNICIAN']);
      final bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bar.items.map((i) => i.label), ['Activos', 'Alertas', 'Órdenes de trabajo', 'Perfil']);
    });
  });

  group('activo: editar y dar de baja', () {
    testWidgets('el detalle ofrece menú, historial y el formulario guarda la ficha completa', (tester) async {
      await pumpApp(tester);
      await open(tester, '/assets/asset1');
      expect(find.text('Historial de fallas y disponibilidad'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar activo'));
      await tester.pumpAndSettle();

      expect(find.text('Código (no editable)'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Compresor 3'), 'Compresor 3 B');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(assets.lastUpdate!.name, 'Compresor 3 B');
      expect(assets.lastUpdate!.plantId, 'plant1'); // campo no editable viaja igual
      expect(assets.lastUpdate!.productionLine, 'L1');
      expect(find.text('Activo actualizado'), findsOneWidget);
    });

    testWidgets('formulario: nombre vacío no se envía', (tester) async {
      await pumpApp(tester);
      await open(tester, '/assets/asset1/edit');
      await tester.enterText(find.widgetWithText(TextFormField, 'Compresor 3'), '');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Obligatorio'), findsOneWidget);
      expect(assets.lastUpdate, isNull);
    });

    testWidgets('activo inactivo no ofrece editar ni baja', (tester) async {
      assets.detail = makeAssetDetail(active: false);
      await pumpApp(tester);
      await open(tester, '/assets/asset1');
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('baja con órdenes abiertas: 409 → diálogo con el número → confirma → force=true', (tester) async {
      assets.conflictUnlessForce = true;
      await pumpApp(tester);
      await open(tester, '/assets/asset1');
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pumpAndSettle();

      expect(find.textContaining('tiene 2 órdenes de trabajo abiertas'), findsOneWidget);
      expect(assets.deactivateCalls, [false]); // aún sin force

      await tester.tap(find.text('Dar de baja de todos modos'));
      await tester.pumpAndSettle();
      expect(assets.deactivateCalls, [false, true]);
      expect(find.textContaining('fue dado de baja'), findsOneWidget);
    });

    testWidgets('baja con órdenes abiertas: si el usuario vuelve, no se fuerza', (tester) async {
      assets.conflictUnlessForce = true;
      await pumpApp(tester);
      await open(tester, '/assets/asset1');
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(assets.deactivateCalls, [false]);
    });
  });

  group('reportes', () {
    testWidgets('disponibilidad: últimos 30 días por defecto, %, tiempo detenido e intervalos', (tester) async {
      await pumpApp(tester);
      await open(tester, '/assets/asset1/availability');

      expect(reports.lastRange!.to.difference(reports.lastRange!.from).inDays, 30);
      expect(find.text('98.50 %'), findsOneWidget);
      expect(find.text('Tiempo total detenido: 10 h 30 min'), findsOneWidget);
      expect(find.text('Paros (1)'), findsOneWidget);
      expect(find.textContaining('Duración: 2 h 30 min'), findsOneWidget);
      expect(find.text('Alertas (1)'), findsOneWidget);
    });

    testWidgets('disponibilidad: exportar guarda y comparte el CSV', (tester) async {
      await pumpApp(tester);
      await open(tester, '/assets/asset1/availability');
      await tester.tap(find.byTooltip('Exportar CSV'));
      await tester.pumpAndSettle();
      expect(reports.calls, contains('export'));
      expect(exporter.fileName, startsWith('historial_mantenimiento_'));
      expect(exporter.mimeType, 'text/csv');
    });

    testWidgets('disponibilidad: sin eventos muestra el mensaje y 100 %', (tester) async {
      reports.availability = AvailabilityReport(
          assetId: 'asset1',
          assetCode: 'COMP-003',
          from: DateTime.utc(2026, 11, 1),
          to: DateTime.utc(2026, 11, 20),
          availabilityPercent: 100,
          downtime: Duration.zero,
          period: const Duration(days: 19),
          hasEvents: false,
          events: const [],
        );
      await pumpApp(tester);
      await open(tester, '/assets/asset1/availability');
      expect(find.text('100 %'), findsOneWidget);
      expect(find.text('Sin alertas ni paros en el período'), findsOneWidget);
    });

    testWidgets('comparación: multi-selección → tabla → exportar lo mismo', (tester) async {
      reports.rows = const [
        ComparisonRow(
            assetId: 'asset1', assetCode: 'COMP-003', assetName: 'Compresor 3', alerts: 4,
            criticalAlerts: 1, stops: 2, downtime: Duration(hours: 1), availabilityPercent: 99.5),
      ];
      await pumpApp(tester);
      await tester.tap(find.text('Comparar activos'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona al menos un activo'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Generar reporte (1)'));
      await tester.pumpAndSettle();

      expect(reports.lastIds, ['asset1']);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('99.50 %'), findsOneWidget);

      await tester.tap(find.byTooltip('Exportar CSV'));
      await tester.pumpAndSettle();
      expect(exporter.fileName, isNotNull);
      expect(reports.lastIds, ['asset1']);
    });
  });

  group('suscripción', () {
    testWidgets('muestra plan, consumo, renovación y la advertencia nearLimit', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Suscripción'));
      await tester.pumpAndSettle();
      expect(find.text('Plan Básico'), findsOneWidget);
      expect(find.textContaining('9 de 10'), findsWidgets);
      expect(find.text('Cerca del límite de tu plan'), findsOneWidget);
      expect(find.textContaining('Fecha de renovación: 14/12/2026'), findsOneWidget);
    });

    testWidgets('sin nearLimit no hay advertencia', (tester) async {
      subscriptions.subscription = makeSubscription(used: 2, nearLimit: false);
      await pumpApp(tester);
      await tester.tap(find.text('Suscripción'));
      await tester.pumpAndSettle();
      expect(find.text('Cerca del límite de tu plan'), findsNothing);
    });

    testWidgets('downgrade bloqueado dice cuántos activos dar de baja', (tester) async {
      subscriptions.changeFailure = const ConflictFailure('HTTP 409');
      await pumpApp(tester);
      await open(tester, '/subscription/plans');
      // Inicial (límite 3) con 9 activos en uso → hay que bajar 6.
      await tester.tap(find.descendant(
          of: find.widgetWithText(Card, 'Inicial'), matching: find.text('Elegir')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('dar de baja 6 activos'), findsOneWidget);
    });

    testWidgets('cambio de plan válido confirma y envía planId', (tester) async {
      await pumpApp(tester);
      await open(tester, '/subscription/plans');
      await tester.tap(find.descendant(
          of: find.widgetWithText(Card, 'Pro'), matching: find.text('Elegir')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();
      expect(subscriptions.requestedPlan, 'p-pro');
      expect(find.text('Plan actualizado: Pro'), findsOneWidget);
    });
  });

  group('perfil', () {
    testWidgets('editar nombre envía PATCH y refresca', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Gerente Uno'), findsOneWidget);

      await tester.tap(find.text('Editar nombre'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Gerente Dos');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(users.renamedTo, 'Gerente Dos');
      expect(find.text('Gerente Dos'), findsOneWidget);
    });

    testWidgets('cerrar sesión limpia el almacén seguro y vuelve al login', (tester) async {
      await pumpApp(tester);
      expect(store.session, isNotNull);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión').last);
      await tester.pumpAndSettle();

      expect(store.session, isNull);
      expect(find.text('Entrar'), findsOneWidget);
    });
  });
}
