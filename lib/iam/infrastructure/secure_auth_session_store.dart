import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session.dart';
import '../domain/auth_session_store.dart';

/// Guarda la sesión en el almacenamiento seguro del dispositivo
/// (Keychain / EncryptedSharedPreferences) y la mantiene en memoria para que
/// leer el token en cada petición no toque el disco.
class SecureAuthSessionStore implements AuthSessionStore {
  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;
  AuthSession? _cached;
  bool _loaded = false;

  SecureAuthSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AuthSession?> read() async {
    if (_loaded) return _cached;
    final raw = await _storage.read(key: _key);
    _cached = raw == null ? null : _decode(raw);
    _loaded = true;
    return _cached;
  }

  @override
  Future<void> save(AuthSession session) async {
    _cached = session;
    _loaded = true;
    await _storage.write(key: _key, value: _encode(session));
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _key);
  }

  static String _encode(AuthSession s) => jsonEncode({
        'accessToken': s.accessToken,
        'tokenType': s.tokenType,
        'expiresAt': s.expiresAt.toIso8601String(),
        'userId': s.userId,
        'tenantId': s.tenantId,
        'roles': s.roles,
      });

  /// Devuelve null si el contenido guardado está corrupto.
  static AuthSession? _decode(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession(
        accessToken: j['accessToken'] as String,
        tokenType: j['tokenType'] as String,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        userId: j['userId'] as String,
        tenantId: j['tenantId'] as String,
        roles: List<String>.from(j['roles'] as List),
      );
    } catch (_) {
      return null;
    }
  }
}
