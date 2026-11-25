import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/core/network/api_client.dart';
import 'package:predictivemaintain_flutter_app/iam/infrastructure/user_repository_impl.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/severity.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/alert_repository_impl.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/work_order_repository_impl.dart';

ApiClient api(MockClientHandler h) => ApiClient(
    baseUrl: 'https://api.test/api/v1', tokenProvider: () async => 't', httpClient: MockClient(h));

const _order = '''
{"id":"w1","alertId":"a1","assetId":"s1","assetCode":"C","assetName":"N","severity":"CRITICAL",
"assignedUserId":null,"status":"OPEN","summary":"","openedAt":"2026-10-11T00:00:00Z",
"completedAt":null,"version":5}''';

const _alert = '''
{"id":"a1","assetId":"s1","assetCode":"C","assetName":"N","severity":"WARNING","status":"CONFIRMED",
"raisedAt":"2026-10-10T03:44:43Z","discardReason":null,"version":4,"diagnostic":null}''';

void main() {
  group('alertas', () {
    test('filtros y página se envían como query con nombres del backend', () async {
      late Uri url;
      final repo = AlertRepositoryImpl(api((r) async {
        url = r.url;
        return http.Response('{"items":[],"page":1,"size":20,"totalElements":0,"totalPages":1}', 200);
      }));
      await repo.getAlerts(status: AlertStatus.inReview, severity: Severity.critical, page: 1);
      expect(url.path, '/api/v1/alerts');
      expect(url.queryParameters, {'status': 'IN_REVIEW', 'severity': 'CRITICAL', 'page': '1'});
    });

    test('sin filtros no manda query', () async {
      late Uri url;
      final repo = AlertRepositoryImpl(api((r) async {
        url = r.url;
        return http.Response('{"items":[],"page":0,"size":20,"totalElements":0,"totalPages":0}', 200);
      }));
      await repo.getAlerts();
      expect(url.hasQuery, isFalse);
    });

    test('descartar: PATCH /alerts/{id}/status con status, reason y expectedVersion', () async {
      late http.Request req;
      final repo = AlertRepositoryImpl(api((r) async {
        req = r;
        return http.Response(_alert, 200);
      }));
      final a = await repo.updateStatus(
          id: 'a1', status: AlertStatus.discarded, reason: 'ruido', expectedVersion: 3);
      expect(req.method, 'PATCH');
      expect(req.url.path, '/api/v1/alerts/a1/status');
      expect(jsonDecode(req.body), {'status': 'DISCARDED', 'reason': 'ruido', 'expectedVersion': 3});
      expect(a.version, 4);
    });

    test('getAlert mapea el diagnóstico nulo', () async {
      final repo = AlertRepositoryImpl(api((_) async => http.Response(_alert, 200)));
      expect((await repo.getAlert('a1')).diagnostic, isNull);
    });
  });

  group('órdenes de trabajo', () {
    test('parsea OPEN (antes fallaba: el enum no tenía open)', () async {
      final repo = WorkOrderRepositoryImpl(api((_) async => http.Response(_order, 200)));
      expect((await repo.getWorkOrder('w1')).status, WorkOrderStatus.open);
    });

    test('lista con status IN_PROGRESS', () async {
      late Uri url;
      final repo = WorkOrderRepositoryImpl(api((r) async {
        url = r.url;
        return http.Response('{"items":[],"page":0,"size":20,"totalElements":0,"totalPages":0}', 200);
      }));
      await repo.getWorkOrders(status: WorkOrderStatus.inProgress);
      expect(url.queryParameters, {'status': 'IN_PROGRESS'});
    });

    test('crear: POST /work-orders con solo alertId', () async {
      late http.Request req;
      final repo = WorkOrderRepositoryImpl(api((r) async {
        req = r;
        return http.Response(_order, 200);
      }));
      await repo.create('a1');
      expect(req.method, 'POST');
      expect(req.url.path, '/api/v1/work-orders');
      expect(jsonDecode(req.body), {'alertId': 'a1'});
    });

    test('asignar: PATCH /assign con technicianId y expectedVersion', () async {
      late http.Request req;
      final repo = WorkOrderRepositoryImpl(api((r) async {
        req = r;
        return http.Response(_order, 200);
      }));
      await repo.assign(id: 'w1', technicianId: 'u9', expectedVersion: 5);
      expect(req.method, 'PATCH');
      expect(req.url.path, '/api/v1/work-orders/w1/assign');
      expect(jsonDecode(req.body), {'technicianId': 'u9', 'expectedVersion': 5});
    });

    test('cambio de estado: PATCH /status con status, summary y expectedVersion', () async {
      late http.Request req;
      final repo = WorkOrderRepositoryImpl(api((r) async {
        req = r;
        return http.Response(_order, 200);
      }));
      await repo.updateStatus(
          id: 'w1', status: WorkOrderStatus.cancelled, summary: 'motivo', expectedVersion: 5);
      expect(req.url.path, '/api/v1/work-orders/w1/status');
      expect(jsonDecode(req.body),
          {'status': 'CANCELLED', 'summary': 'motivo', 'expectedVersion': 5});
    });

    test('409 se mapea a ConflictFailure', () async {
      final repo = WorkOrderRepositoryImpl(
          api((_) async => http.Response('{"message":"version mismatch"}', 409)));
      await expectLater(
        repo.assign(id: 'w1', technicianId: 'u', expectedVersion: 1),
        throwsA(isA<ConflictFailure>().having((f) => f.serverMessage, 'msg', 'version mismatch')),
      );
    });
  });

  test('usuarios: GET /users?role=TECHNICIAN&active=true', () async {
    late Uri url;
    final repo = UserRepositoryImpl(api((r) async {
      url = r.url;
      return http.Response(
          '{"items":[{"id":"u1","tenantId":"t","email":"a@b.c","displayName":"Ana","active":true,"roles":["TECHNICIAN"]}],'
          '"page":0,"size":20,"totalElements":1,"totalPages":1}',
          200);
    }));
    final page = await repo.getUsers(role: 'TECHNICIAN', active: true);
    expect(url.queryParameters, {'role': 'TECHNICIAN', 'active': 'true'});
    expect(page.items.single.displayName, 'Ana');
  });
}
