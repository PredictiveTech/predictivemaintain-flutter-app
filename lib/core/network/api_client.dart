import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../error/failure.dart';

/// Cliente HTTP único de la app.
///
/// * Antepone [baseUrl] a cada ruta.
/// * Agrega `Authorization: Bearer {token}` (el token se pide en cada envío a
///   [tokenProvider], así siempre se usa el vigente).
/// * Decodifica el JSON de la respuesta.
/// * Traduce errores HTTP y de transporte a [Failure].
/// * Avisa por [onUnauthorized] cuando una petición autenticada recibe 401.
class ApiClient {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final void Function()? onUnauthorized;
  final http.Client _inner;

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    this.onUnauthorized,
    http.Client? httpClient,
  }) : _inner = httpClient ?? http.Client();

  /// GET [path]; devuelve el JSON decodificado (`Map`, `List`…) o null si el
  /// cuerpo está vacío.
  Future<dynamic> get(String path,
          {Map<String, String?> query = const {}, bool authenticated = true}) =>
      _send('GET', path, query: query, authenticated: authenticated);

  /// PUT [path] con [body] serializado como JSON.
  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body, authenticated: true);

  /// DELETE [path].
  Future<dynamic> delete(String path,
          {Map<String, String?> query = const {}}) =>
      _send('DELETE', path, query: query, authenticated: true);

  /// GET de un recurso binario/texto (p. ej. CSV): devuelve los bytes tal cual.
  Future<Uint8List> getBytes(String path,
      {Map<String, String?> query = const {}, String? accept}) async {
    final response = await _request('GET', path,
        query: query, authenticated: true, headers: {'Accept': ?accept});
    return response.bodyBytes;
  }

  /// PATCH [path] con [body] serializado como JSON.
  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body, authenticated: true);

  /// POST [path] con [body] serializado como JSON.
  Future<dynamic> post(String path,
          {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String?> query = const {},
    required bool authenticated,
  }) async {
    final response =
        await _request(method, path, body: body, query: query, authenticated: authenticated);
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      throw MalformedResponseFailure(e.toString());
    }
  }

  /// Envía la petición y devuelve la respuesta 2xx; lanza [Failure] si no.
  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String?> query = const {},
    Map<String, String> headers = const {},
    required bool authenticated,
  }) async {
    // Los parámetros null se omiten (filtros no seleccionados).
    final params = {
      for (final e in query.entries)
        if (e.value != null) e.key: e.value!,
    };
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(
      method,
      params.isEmpty ? uri : uri.replace(queryParameters: params),
    )..headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      if (authenticated) {
        final token = await tokenProvider();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      response = await http.Response.fromStream(await _inner.send(request));
    } catch (e) {
      throw NetworkFailure(e.toString());
    }

    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      final failure = _mapError(status, response.body);
      if (failure is UnauthorizedFailure && authenticated) {
        onUnauthorized?.call();
      }
      throw failure;
    }
    return response;
  }

  Failure _mapError(int status, String body) {
    final serverMessage = _extractMessage(body);
    final message = 'HTTP $status';
    return switch (status) {
      401 => UnauthorizedFailure(message, serverMessage: serverMessage),
      409 => ConflictFailure(message, serverMessage: serverMessage),
      400 || 422 => ValidationFailure(message,
          statusCode: status, serverMessage: serverMessage),
      _ => ServerFailure(message,
          statusCode: status, serverMessage: serverMessage),
    };
  }

  static String? _extractMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
    } catch (_) {}
    return null;
  }

  void close() => _inner.close();
}

/// Ejecuta [parse] (típicamente DTO.fromJson + toDomain) y convierte
/// cualquier error de formato en [MalformedResponseFailure].
T parseResponse<T>(T Function() parse) {
  try {
    return parse();
  } on Failure {
    rethrow;
  } catch (e) {
    throw MalformedResponseFailure(e.toString());
  }
}
