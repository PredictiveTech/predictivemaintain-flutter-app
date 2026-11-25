import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/application/get_technicians_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/assign_work_order_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/confirm_alert_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/create_work_order_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/discard_alert_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/get_alerts_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/update_work_order_status_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/severity.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_status.dart';

import 'support/fakes.dart';

void main() {
  group('Confirm / Discard alert', () {
    test('confirmar envía CONFIRMED con la versión vista', () async {
      final repo = FakeAlertRepository([makeAlert(version: 3)]);
      await ConfirmAlertUseCase(repo)(repo.alerts.first);
      expect(repo.lastUpdate, {
        'id': 'a1',
        'status': AlertStatus.confirmed,
        'reason': null,
        'expectedVersion': 3,
      });
    });

    test('descartar sin motivo falla con ValidationFailure y no llama al repo', () async {
      final repo = FakeAlertRepository([makeAlert()]);
      for (final reason in ['', '   ']) {
        await expectLater(
            DiscardAlertUseCase(repo)(repo.alerts.first, reason), throwsA(isA<ValidationFailure>()));
      }
      expect(repo.lastUpdate, isNull);
    });

    test('descartar con motivo lo envía recortado', () async {
      final repo = FakeAlertRepository([makeAlert()]);
      await DiscardAlertUseCase(repo)(repo.alerts.first, '  sensor descalibrado ');
      expect(repo.lastUpdate!['status'], AlertStatus.discarded);
      expect(repo.lastUpdate!['reason'], 'sensor descalibrado');
    });

    test('motivo de más de 500 caracteres se rechaza', () async {
      final repo = FakeAlertRepository([makeAlert()]);
      await expectLater(DiscardAlertUseCase(repo)(repo.alerts.first, 'x' * 501),
          throwsA(isA<ValidationFailure>()));
    });

    test('propaga el 409 del backend', () async {
      final repo = FakeAlertRepository([makeAlert()])..failure = const ConflictFailure('HTTP 409');
      await expectLater(
          ConfirmAlertUseCase(repo)(repo.alerts.first), throwsA(isA<ConflictFailure>()));
    });
  });

  group('GetAlerts', () {
    test('pasa filtros y página al repositorio', () async {
      final repo = FakeAlertRepository([makeAlert()]);
      await GetAlertsUseCase(repo)(status: AlertStatus.confirmed, severity: Severity.critical, page: 2);
      expect(repo.calls.single, 'getAlerts status=AlertStatus.confirmed severity=Severity.critical page=2');
    });
  });

  group('CreateWorkOrder', () {
    test('solo se permite desde una alerta confirmada', () async {
      final repo = FakeWorkOrderRepository();
      for (final s in [AlertStatus.inReview, AlertStatus.discarded, AlertStatus.resolved]) {
        await expectLater(CreateWorkOrderUseCase(repo)(makeAlert(status: s)),
            throwsA(isA<ConflictFailure>()));
      }
      expect(repo.last, isNull);
    });

    test('desde una alerta confirmada envía su id', () async {
      final repo = FakeWorkOrderRepository();
      final order = await CreateWorkOrderUseCase(repo)(makeAlert(status: AlertStatus.confirmed));
      expect(repo.last, {'op': 'create', 'alertId': 'a1'});
      expect(order.status, WorkOrderStatus.open);
    });
  });

  group('AssignWorkOrder', () {
    test('envía técnico y expectedVersion de la orden vista', () async {
      final repo = FakeWorkOrderRepository([makeOrder(version: 5)]);
      final updated = await AssignWorkOrderUseCase(repo)(repo.orders.first, 'tech-1');
      expect(repo.last, {'op': 'assign', 'id': 'w1', 'technicianId': 'tech-1', 'expectedVersion': 5});
      expect(updated.assignedUserId, 'tech-1');
    });

    test('reasignar también envía la versión', () async {
      final repo = FakeWorkOrderRepository(
          [makeOrder(status: WorkOrderStatus.assigned, assignedUserId: 'tech-1', version: 6)]);
      await AssignWorkOrderUseCase(repo)(repo.orders.first, 'tech-2');
      expect(repo.last!['expectedVersion'], 6);
      expect(repo.last!['technicianId'], 'tech-2');
    });

    test('propaga el 409', () async {
      final repo = FakeWorkOrderRepository([makeOrder()])..failure = const ConflictFailure('HTTP 409');
      await expectLater(AssignWorkOrderUseCase(repo)(repo.orders.first, 't'), throwsA(isA<ConflictFailure>()));
    });
  });

  group('UpdateWorkOrderStatus', () {
    test('cancelar exige motivo y envía expectedVersion', () async {
      final repo = FakeWorkOrderRepository([makeOrder(version: 9)]);
      final uc = UpdateWorkOrderStatusUseCase(repo);
      await expectLater(uc(repo.orders.first, WorkOrderStatus.cancelled), throwsA(isA<ValidationFailure>()));
      await expectLater(uc(repo.orders.first, WorkOrderStatus.cancelled, summary: ' '), throwsA(isA<ValidationFailure>()));
      expect(repo.last, isNull);

      await uc(repo.orders.first, WorkOrderStatus.cancelled, summary: 'Falsa alarma');
      expect(repo.last, {
        'op': 'status',
        'id': 'w1',
        'status': WorkOrderStatus.cancelled,
        'summary': 'Falsa alarma',
        'expectedVersion': 9,
      });
    });

    test('completar exige acciones correctivas; iniciar no exige resumen', () async {
      final repo = FakeWorkOrderRepository([makeOrder()]);
      final uc = UpdateWorkOrderStatusUseCase(repo);
      await expectLater(uc(repo.orders.first, WorkOrderStatus.completed), throwsA(isA<ValidationFailure>()));
      await uc(repo.orders.first, WorkOrderStatus.inProgress);
      expect(repo.last!['expectedVersion'], 5);
    });

    test('estados que el backend no acepta como destino se rechazan', () async {
      final repo = FakeWorkOrderRepository([makeOrder()]);
      for (final s in [WorkOrderStatus.open, WorkOrderStatus.assigned]) {
        await expectLater(UpdateWorkOrderStatusUseCase(repo)(repo.orders.first, s, summary: 'x'),
            throwsA(isA<ValidationFailure>()));
      }
    });
  });

  group('GetTechnicians', () {
    test('pide role=TECHNICIAN activos y recorre todas las páginas', () async {
      final repo = FakeUserRepository([
        [makeUser('1', 'Ana'), makeUser('2', 'Beto')],
        [makeUser('3', 'Carla')],
      ]);
      final list = await GetTechniciansUseCase(repo)();
      expect(list.map((u) => u.id), ['1', '2', '3']);
      expect(repo.requested, [0, 1]);
      expect(repo.lastRole, 'TECHNICIAN');
      expect(repo.lastActive, true);
    });
  });
}
