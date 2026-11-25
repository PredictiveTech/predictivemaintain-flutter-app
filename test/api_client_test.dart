import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:predictivemaintain_flutter_app/core/error/failure.dart';
import 'package:predictivemaintain_flutter_app/core/network/api_client.dart';

ApiClient clientWith(
  MockClientHandler handler, {
  String? token = 'tok',
  void Function()? onUnauthorized,
}) =>
    ApiClient(
      baseUrl: 'https://api.test/api/v1',
      tokenProvider: () async => token,
      onUnauthorized: onUnauthorized,
      httpClient: MockClient(handler),
    );

void main() {
  group('peticiones correctas', () {
    test('antepone baseUrl, agrega Bearer y decodifica JSON', () async {
      late http.Request seen;
      final api = clientWith((req) async {
        seen = req;
        return http.Response('{"a":1}', 200);
      });

      final json = await api.get('/assets');

      expect(seen.url.toString(), 'https://api.test/api/v1/assets');
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(json, {'a': 1});
    });

    test('post serializa el cuerpo y no envía token si authenticated=false', () async {
      late http.Request seen;
      final api = clientWith((req) async {
        seen = req;
        return http.Response('{}', 200);
      });

      await api.post('/auth/login', body: {'email': 'e'}, authenticated: false);

      expect(seen.headers.containsKey('Authorization'), isFalse);
      expect(seen.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(seen.body), {'email': 'e'});
    });

    test('sin token no agrega el header', () async {
      late http.Request seen;
      final api = clientWith((req) async {
        seen = req;
        return http.Response('[]', 200);
      }, token: null);

      await api.get('/x');

      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('cuerpo vacío devuelve null', () async {
      final api = clientWith((_) async => http.Response('', 204));
      expect(await api.get('/x'), isNull);
    });
  });

  group('mapeo de errores', () {
    Future<Failure> failureFor(int status, [String body = '']) async {
      final api = clientWith((_) async => http.Response(body, status));
      try {
        await api.get('/x');
      } on Failure catch (f) {
        return f;
      }
      fail('Se esperaba un Failure');
    }

    test('401 -> UnauthorizedFailure', () async {
      final f = await failureFor(401);
      expect(f, isA<UnauthorizedFailure>());
      expect(f.statusCode, 401);
    });

    test('400 y 422 -> ValidationFailure', () async {
      expect(await failureFor(400), isA<ValidationFailure>());
      expect(await failureFor(422), isA<ValidationFailure>());
    });

    test('403, 404 y 5xx -> ServerFailure con statusCode', () async {
      for (final code in [403, 404, 500, 503]) {
        final f = await failureFor(code);
        expect(f, isA<ServerFailure>(), reason: 'HTTP $code');
        expect(f.statusCode, code);
        expect(f.message, 'HTTP $code');
      }
    });

    test('extrae "message" del cuerpo de error', () async {
      final f = await failureFor(401, '{"message":"Credenciales inválidas"}');
      expect(f.serverMessage, 'Credenciales inválidas');
    });

    test('cuerpo de error ilegible -> serverMessage null', () async {
      expect((await failureFor(500, '<html>')).serverMessage, isNull);
      expect((await failureFor(500, '{"message":3}')).serverMessage, isNull);
    });

    test('error de transporte -> NetworkFailure', () async {
      final api = clientWith((_) async => throw http.ClientException('sin red'));
      await expectLater(api.get('/x'), throwsA(isA<NetworkFailure>()));
    });

    test('JSON inválido en 200 -> MalformedResponseFailure', () async {
      final api = clientWith((_) async => http.Response('no-json', 200));
      await expectLater(api.get('/x'), throwsA(isA<MalformedResponseFailure>()));
    });
  });

  group('señal de 401', () {
    test('se emite en una petición autenticada', () async {
      var calls = 0;
      final api = clientWith((_) async => http.Response('', 401),
          onUnauthorized: () => calls++);

      await expectLater(api.get('/x'), throwsA(isA<UnauthorizedFailure>()));
      expect(calls, 1);
    });

    test('no se emite con authenticated=false (p. ej. login)', () async {
      var calls = 0;
      final api = clientWith((_) async => http.Response('', 401),
          onUnauthorized: () => calls++);

      await expectLater(
        api.post('/auth/login', body: {}, authenticated: false),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(calls, 0);
    });

    test('no se emite en otros errores', () async {
      var calls = 0;
      final api = clientWith((_) async => http.Response('', 500),
          onUnauthorized: () => calls++);

      await expectLater(api.get('/x'), throwsA(isA<ServerFailure>()));
      expect(calls, 0);
    });
  });

  group('parseResponse', () {
    test('convierte TypeError en MalformedResponseFailure', () {
      expect(
        () => parseResponse(() => ({'a': 1})['a'] as String),
        throwsA(isA<MalformedResponseFailure>()),
      );
    });
  });
}
