import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/core/network/api_client.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/asset_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/asset_repository_impl.dart';

AssetRepositoryImpl repoWith(MockClientHandler handler) => AssetRepositoryImpl(
      ApiClient(
        baseUrl: 'https://api.test/api/v1',
        tokenProvider: () async => 'tok',
        httpClient: MockClient(handler),
      ),
    );

const _assetsPage = '''
{"items":[{"id":7,"code":"P-01","name":"Bomba 1","location":"Planta A",
"assetType":"PUMP","criticality":"HIGH","active":true,"status":"OPERATIONAL",
"sensorTypes":["TEMPERATURE"]}],
"page":0,"size":20,"totalElements":1,"totalPages":1}
''';

void main() {
  test('getAssets pide /assets y mapea a dominio', () async {
    late Uri url;
    final repo = repoWith((req) async {
      url = req.url;
      return http.Response(_assetsPage, 200);
    });

    final page = await repo.getAssets();

    expect(url.path, '/api/v1/assets');
    expect(page.totalElements, 1);
    expect(page.items.single.id, '7');
    expect(page.items.single.name, 'Bomba 1');
    expect(page.items.single.status, AssetStatus.operational);
  });

  test('getAssets propaga el Failure del cliente', () async {
    final repo = repoWith((_) async => http.Response('', 503));
    await expectLater(
      repo.getAssets(),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503)),
    );
  });

  test('getAssets con cuerpo de forma inesperada -> MalformedResponseFailure', () async {
    final repo = repoWith((_) async => http.Response('{"items":[{"id":1}]}', 200));
    await expectLater(repo.getAssets(), throwsA(isA<MalformedResponseFailure>()));
  });

  test('getSensors pide /assets/{id}/sensors y acepta lista vacía', () async {
    late Uri url;
    final repo = repoWith((req) async {
      url = req.url;
      return http.Response('[]', 200);
    });

    expect(await repo.getSensors('7'), isEmpty);
    expect(url.path, '/api/v1/assets/7/sensors');
  });
}
