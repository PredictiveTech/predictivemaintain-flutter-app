/// Sesión devuelta por POST /api/v1/auth/login.
class AuthSession {
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final String userId;
  final String tenantId;
  final List<String> roles;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.userId,
    required this.tenantId,
    required this.roles,
  });
}
