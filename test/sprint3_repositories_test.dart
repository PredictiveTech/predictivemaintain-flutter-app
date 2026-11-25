import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/core/network/api_client.dart';
import 'package:predictivemaintain_flutter_app/iam/infrastructure/user_repository_impl.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_update.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/availability_report.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/criticality.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/report_range.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/asset_repository_impl.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/report_repository_impl.dart';
import 'package:predictivemaintain_flutter_app/subscription/domain/subscription.dart';
import 'package:predictivemaintain_flutter_app/subscription/infrastructure/subscription_repository_impl.dart';

ApiClient api(MockClientHandler h) => ApiClient(
    baseUrl: 'https://api.test/api/v1', tokenProvider: () async => 't', httpClient: MockClient(h));

final range = ReportRange(DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 20, 23, 59, 59));

const _asset = '''
{"id":"asset1","code":"C","name":"N","location":"L","plantId":"p1","productionLine":null,
"assetType":"PUMP","criticality":"HIGH","latitude":null,"longitude":null,"active":false}''';

const _subscription = '''
{"id":"s1","status":"ACTIVE","startsAt":"2026-10-01T00:00:00Z","endsAt":"2026-12-14T00:00:00Z",
"monitoringAllowed":true,
"plan":{"id":"p1","name":"Básico","assetLimit":10,"amount":29.0,"currency":"USD"},
"capacity":{"limit":10,"used":9,"available":1,"usagePercent":90.0,"nearLimit":true},
"expiry":{"daysRemaining":20,"expiresSoon":false,"expired":false}}''';

void main() {
  group('activos', () {
    test('PUT /assets/{id} envía la ficha completa con criticidad del backend', () async {
      late http.Request req;
      final repo = AssetRepositoryImpl(api((r) async {
        req = r;
        return http.Response(_asset, 200);
      }));
      await repo.updateAsset(
        'asset1',
        const AssetUpdate(
            name: 'N', location: 'L', assetType: 'PUMP', criticality: Criticality.critical,
            plantId: 'p1', productionLine: 'L1', latitude: -12.5, longitude: -77.1),
      );
      expect(req.method, 'PUT');
      expect(req.url.path, '/api/v1/assets/asset1');
      expect(jsonDecode(req.body), {
        'name': 'N',
        'location': 'L',
        'assetType': 'PUMP',
        'criticality': 'CRITICAL',
        'plantId': 'p1',
        'productionLine': 'L1',
        'latitude': -12.5,
        'longitude': -77.1,
      });
    });

    test('DELETE sin force no manda query; con force manda force=true', () async {
      final seen = <Uri>[];
      final repo = AssetRepositoryImpl(api((r) async {
        expect(r.method, 'DELETE');
        seen.add(r.url);
        return http.Response(_asset, 200);
      }));
      final detail = await repo.deactivateAsset('asset1');
      await repo.deactivateAsset('asset1', force: true);
      expect(seen[0].hasQuery, isFalse);
      expect(seen[1].queryParameters, {'force': 'true'});
      expect(detail.active, isFalse);
    });

    test('DELETE 409 se mapea a ConflictFailure', () async {
      final repo = AssetRepositoryImpl(api((_) async => http.Response('{"code":"X"}', 409)));
      await expectLater(repo.deactivateAsset('asset1'), throwsA(isA<ConflictFailure>()));
    });
  });

  group('reportes', () {
    test('availability: assetId, from y to en UTC ISO-8601', () async {
      late Uri url;
      final repo = ReportRepositoryImpl(api((r) async {
        url = r.url;
        return http.Response(
            '{"assetId":"asset1","assetCode":"C","from":"2026-11-01T00:00:00Z","to":"2026-11-20T23:59:59Z",'
            '"availabilityPercent":97.25,"downtimeSeconds":9000,"periodSeconds":1728000,"hasEvents":true,'
            '"events":[{"type":"DOWNTIME","referenceId":"d1","occurredAt":"2026-11-02T08:00:00Z","endedAt":"2026-11-02T10:30:00Z"},'
            '{"type":"ALERT","referenceId":"a1","occurredAt":"2026-11-03T08:00:00Z","endedAt":null,"severity":"CRITICAL","status":"CONFIRMED"}]}',
            200);
      }));
      final r = await repo.getAvailability('asset1', range);
      expect(url.path, '/api/v1/reports/availability');
      expect(url.queryParameters, {
        'assetId': 'asset1',
        'from': '2026-11-01T00:00:00.000Z',
        'to': '2026-11-20T23:59:59.000Z',
      });
      expect(r.availabilityPercent, 97.25);
      expect(r.downtime, const Duration(seconds: 9000));
      expect(r.downtimes.single.endedAt, DateTime.utc(2026, 11, 2, 10, 30));
      expect(r.events.last.type, AssetEventType.alert);
    });

    test('comparison: assetIds separados por coma y filas mapeadas', () async {
      late Uri url;
      final repo = ReportRepositoryImpl(api((r) async {
        url = r.url;
        return http.Response(
            '[{"assetId":"a1","assetCode":"C1","assetName":"N1","alerts":4,"criticalAlerts":1,"stops":2,'
            '"downtimeSeconds":3600,"availabilityPercent":99.5}]',
            200);
      }));
      final rows = await repo.compare(['a1', 'a2'], range);
      expect(url.queryParameters['assetIds'], 'a1,a2');
      expect(rows.single.criticalAlerts, 1);
      expect(rows.single.downtime, const Duration(hours: 1));
    });

    test('export: devuelve los bytes del CSV y pide Accept: text/csv', () async {
      late http.Request req;
      final repo = ReportRepositoryImpl(api((r) async {
        req = r;
        return http.Response('type,date\nALERT,2026-11-03\n', 200,
            headers: {'content-type': 'text/csv; charset=utf-8'});
      }));
      final bytes = await repo.exportHistory(['a1'], range);
      expect(req.url.path, '/api/v1/reports/history/export');
      expect(req.headers['Accept'], 'text/csv');
      expect(utf8.decode(bytes), 'type,date\nALERT,2026-11-03\n');
    });

    test('export: 404 expone el mensaje explicativo del backend', () async {
      final repo = ReportRepositoryImpl(
          api((_) async => http.Response('{"message":"No hay datos para exportar"}', 404)));
      await expectLater(
        repo.exportHistory(['a1'], range),
        throwsA(isA<ServerFailure>()
            .having((f) => f.statusCode, 'code', 404)
            .having((f) => f.serverMessage, 'msg', 'No hay datos para exportar')),
      );
    });
  });

  group('suscripción', () {
    test('GET /subscription mapea plan, capacidad y vencimiento', () async {
      final repo = SubscriptionRepositoryImpl(api((_) async => http.Response(_subscription, 200)));
      final s = await repo.getSubscription();
      expect(s.status, SubscriptionStatus.active);
      expect(s.plan.name, 'Básico');
      expect(s.capacity.used, 9);
      expect(s.capacity.nearLimit, isTrue);
      expect(s.endsAt, DateTime.utc(2026, 12, 14));
      expect(s.expiry.daysRemaining, 20);
    });

    test('GET /plans y PUT /subscription/plan con planId', () async {
      late http.Request put;
      final repo = SubscriptionRepositoryImpl(api((r) async {
        if (r.url.path.endsWith('/plans')) {
          return http.Response(
              '[{"id":"p1","name":"Básico","assetLimit":10,"amount":29,"currency":"USD"}]', 200);
        }
        put = r;
        return http.Response(_subscription, 200);
      }));
      expect((await repo.getPlans()).single.amount, 29.0);
      await repo.changePlan('p1');
      expect(put.method, 'PUT');
      expect(put.url.path, '/api/v1/subscription/plan');
      expect(jsonDecode(put.body), {'planId': 'p1'});
    });

    test('PUT plan 409 -> ConflictFailure', () async {
      final repo = SubscriptionRepositoryImpl(api((_) async => http.Response('', 409)));
      await expectLater(repo.changePlan('p1'), throwsA(isA<ConflictFailure>()));
    });
  });

  group('perfil', () {
    const user = '{"id":"u1","tenantId":"t1","email":"a@b.c","displayName":"Ana","active":true,"roles":["MAINTENANCE_MANAGER"]}';

    test('GET /users/me', () async {
      final repo = UserRepositoryImpl(api((r) async {
        expect(r.url.path, '/api/v1/users/me');
        return http.Response(user, 200);
      }));
      expect((await repo.getMe()).roles, ['MAINTENANCE_MANAGER']);
    });

    test('PATCH /users/me con displayName', () async {
      late http.Request req;
      final repo = UserRepositoryImpl(api((r) async {
        req = r;
        return http.Response(user, 200);
      }));
      await repo.updateDisplayName('Ana Nueva');
      expect(req.method, 'PATCH');
      expect(jsonDecode(req.body), {'displayName': 'Ana Nueva'});
    });
  });
}
