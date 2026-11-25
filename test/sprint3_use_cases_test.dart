import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/iam/application/update_display_name_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/compare_assets_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/deactivate_asset_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/export_history_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/get_availability_report_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/application/update_asset_use_case.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_update.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/criticality.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/report_range.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/work_order_status.dart';
import 'package:predictivemaintain_flutter_app/subscription/application/change_plan_use_case.dart';
import 'package:predictivemaintain_flutter_app/subscription/application/get_plans_use_case.dart';

import 'support/fakes.dart';

final now = DateTime(2026, 11, 24, 12);

AssetUpdate update({String name = 'Compresor', double? lat, double? lon, String? line}) => AssetUpdate(
    name: name, location: 'Planta', assetType: 'COMPRESSOR', criticality: Criticality.high,
    plantId: 'p1', productionLine: line, latitude: lat, longitude: lon);

void main() {
  group('ReportRange', () {
    test('recorta "to" a ahora', () {
      final r = ReportRange(now.subtract(const Duration(days: 5)), now.add(const Duration(days: 2)));
      expect(r.validated(now).to, now);
    });

    test('rechaza rango invertido y más de 366 días', () {
      expect(() => ReportRange(now, now.subtract(const Duration(days: 1))).validated(now),
          throwsA(isA<ValidationFailure>()));
      expect(() => ReportRange(now.subtract(const Duration(days: 367)), now).validated(now),
          throwsA(isA<ValidationFailure>()));
      expect(ReportRange(now.subtract(const Duration(days: 366)), now).validated(now).from,
          now.subtract(const Duration(days: 366)));
    });

    test('lastDays(30)', () {
      final r = ReportRange.lastDays(30, now);
      expect(r.to.difference(r.from), const Duration(days: 30));
    });
  });

  group('UpdateAsset', () {
    test('valida obligatorios, longitudes y coordenadas sin llamar al repositorio', () async {
      final repo = FakeAssetRepository();
      final uc = UpdateAssetUseCase(repo);
      for (final bad in [
        update(name: '  '),
        update(name: 'x' * 121),
        update(lat: 91),
        update(lon: -181),
        update(line: 'x' * 101),
      ]) {
        await expectLater(uc('asset1', bad), throwsA(isA<ValidationFailure>()));
      }
      expect(repo.lastUpdate, isNull);
    });

    test('envía la ficha completa (incluido plantId) cuando es válida', () async {
      final repo = FakeAssetRepository();
      await UpdateAssetUseCase(repo)('asset1', update(lat: -12, lon: -77, line: 'L2'));
      expect(repo.lastUpdate!.plantId, 'p1');
      expect(repo.lastUpdate!.productionLine, 'L2');
    });
  });

  group('DeactivateAsset', () {
    test('sin órdenes abiertas da de baja directamente', () async {
      final assets = FakeAssetRepository();
      final result = await DeactivateAssetUseCase(assets, FakeWorkOrderRepository())('asset1');
      expect(result, isA<AssetDeactivated>());
      expect(assets.deactivateCalls, [false]);
    });

    test('409 devuelve NeedsConfirmation con el conteo y NO reintenta solo', () async {
      final assets = FakeAssetRepository()..conflictUnlessForce = true;
      final orders = FakeWorkOrderRepository([
        makeOrder(id: 'o1'), // OPEN del activo
        makeOrder(id: 'o2', status: WorkOrderStatus.assigned),
        makeOrder(id: 'o3', status: WorkOrderStatus.inProgress),
        makeOrder(id: 'o4', status: WorkOrderStatus.completed), // no cuenta
        makeOrder(id: 'o5', status: WorkOrderStatus.cancelled), // no cuenta
      ]);
      final result = await DeactivateAssetUseCase(assets, orders)('asset1');
      expect(result, isA<AssetNeedsConfirmation>().having((r) => r.openWorkOrders, 'n', 3));
      expect(assets.deactivateCalls, [false]); // sin force hasta que el usuario confirme
    });

    test('solo cuenta órdenes del activo pedido', () async {
      final assets = FakeAssetRepository()..conflictUnlessForce = true;
      final other = makeOrder(id: 'x'); // assetId 'asset1'
      final result = await DeactivateAssetUseCase(assets, FakeWorkOrderRepository([other]))('otro');
      expect(result, isA<AssetNeedsConfirmation>().having((r) => r.openWorkOrders, 'n', 0));
    });

    test('con force=true reintenta con force', () async {
      final assets = FakeAssetRepository()..conflictUnlessForce = true;
      final result =
          await DeactivateAssetUseCase(assets, FakeWorkOrderRepository())('asset1', force: true);
      expect(result, isA<AssetDeactivated>());
      expect(assets.deactivateCalls, [true]);
    });

    test('otros errores se propagan', () async {
      final assets = FakeAssetRepository()..failure = const ServerFailure('HTTP 500', statusCode: 500);
      await expectLater(DeactivateAssetUseCase(assets, FakeWorkOrderRepository())('asset1'),
          throwsA(isA<ServerFailure>()));
    });
  });

  group('Reportes', () {
    test('disponibilidad valida y recorta el rango antes de consultar', () async {
      final repo = FakeReportRepository();
      final uc = GetAvailabilityReportUseCase(repo, now: () => now);
      await uc('asset1', ReportRange(now.subtract(const Duration(days: 30)), now.add(const Duration(days: 1))));
      expect(repo.lastRange!.to, now);

      await expectLater(
          uc('asset1', ReportRange(now.subtract(const Duration(days: 400)), now)),
          throwsA(isA<ValidationFailure>()));
      expect(repo.calls, ['availability']);
    });

    test('comparación exige de 1 a 20 activos', () async {
      final repo = FakeReportRepository();
      final uc = CompareAssetsUseCase(repo, now: () => now);
      final range = ReportRange.lastDays(30, now);
      await expectLater(uc([], range), throwsA(isA<ValidationFailure>()));
      await expectLater(uc([for (var i = 0; i < 21; i++) 'a$i'], range), throwsA(isA<ValidationFailure>()));
      expect(repo.calls, isEmpty);
      await uc([for (var i = 0; i < 20; i++) 'a$i'], range);
      expect(repo.lastIds, hasLength(20));
    });

    test('exportar guarda el CSV con nombre por fechas y lo comparte', () async {
      final repo = FakeReportRepository();
      final exporter = FakeFileExporter();
      final uc = ExportHistoryUseCase(repo, exporter, now: () => now);
      final name = await uc(['a1', 'a2'], ReportRange(DateTime(2026, 11, 1), DateTime(2026, 11, 20)));
      expect(name, 'historial_mantenimiento_20261101_20261120.csv');
      expect(exporter.fileName, name);
      expect(exporter.mimeType, 'text/csv');
      expect(String.fromCharCodes(exporter.bytes!), 'a,b\n1,2\n');
      expect(repo.lastIds, ['a1', 'a2']);
    });

    test('si el backend no tiene nada que exportar (404) no se comparte nada', () async {
      final repo = FakeReportRepository()
        ..failure = const ServerFailure('HTTP 404', statusCode: 404, serverMessage: 'Nada que exportar');
      final exporter = FakeFileExporter();
      await expectLater(
        ExportHistoryUseCase(repo, exporter, now: () => now)(['a1'], ReportRange.lastDays(30, now)),
        throwsA(isA<ServerFailure>().having((f) => f.serverMessage, 'msg', 'Nada que exportar')),
      );
      expect(exporter.fileName, isNull);
    });
  });

  group('Planes', () {
    test('GetPlans ordena por límite de activos', () async {
      final plans = await GetPlansUseCase(FakeSubscriptionRepository())();
      expect(plans.map((p) => p.name), ['Inicial', 'Básico', 'Pro']);
    });

    test('cambio válido devuelve la suscripción nueva', () async {
      final repo = FakeSubscriptionRepository();
      final result = await ChangePlanUseCase(repo)(repo.subscription, repo.plans.first);
      expect(repo.requestedPlan, 'p-pro');
      expect(result, isA<PlanChanged>().having((r) => r.subscription.plan.name, 'plan', 'Pro'));
    });

    test('409 de downgrade informa cuántos activos hay que dar de baja', () async {
      final repo = FakeSubscriptionRepository()
        ..subscription = makeSubscription(used: 9, limit: 10)
        ..changeFailure = const ConflictFailure('HTTP 409');
      final inicial = repo.plans.firstWhere((p) => p.id == 'p-free'); // límite 3
      final result = await ChangePlanUseCase(repo)(repo.subscription, inicial);
      expect(result, isA<PlanDowngradeBlocked>().having((r) => r.assetsToDeactivate, 'n', 6));
    });

    test('pedir el plan actual no llama al backend', () async {
      final repo = FakeSubscriptionRepository();
      await ChangePlanUseCase(repo)(repo.subscription, repo.subscription.plan);
      expect(repo.requestedPlan, isNull);
    });

    test('otros errores se propagan', () async {
      final repo = FakeSubscriptionRepository()
        ..changeFailure = const ServerFailure('HTTP 500', statusCode: 500);
      await expectLater(ChangePlanUseCase(repo)(repo.subscription, repo.plans.first),
          throwsA(isA<ServerFailure>()));
    });
  });

  group('Perfil', () {
    test('rechaza nombre vacío y recorta espacios', () async {
      final repo = FakeUserRepository([[]]);
      final uc = UpdateDisplayNameUseCase(repo);
      await expectLater(uc('   '), throwsA(isA<ValidationFailure>()));
      expect(repo.renamedTo, isNull);
      final user = await uc('  Ana Pérez ');
      expect(repo.renamedTo, 'Ana Pérez');
      expect(user.displayName, 'Ana Pérez');
    });
  });
}
