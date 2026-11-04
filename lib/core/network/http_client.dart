import 'package:http/http.dart' as http;

/// Cliente HTTP que agrega `Authorization: Bearer {token}` a cada petición.
///
/// El token se obtiene en cada envío mediante [tokenProvider], de modo que
/// siempre se usa el valor vigente. Si devuelve null o vacío (p. ej. en el
/// login), la petición se envía sin el header.
class HttpClient extends http.BaseClient {
  final http.Client _inner;
  final Future<String?> Function() tokenProvider;

  HttpClient({required this.tokenProvider, http.Client? inner})
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
