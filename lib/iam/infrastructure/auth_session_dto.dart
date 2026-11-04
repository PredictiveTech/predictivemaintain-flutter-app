import '../domain/auth_session.dart';

class AuthSessionDto {
  final String accessToken;
  final String tokenType;
  final String expiresAt;
  final String userId;
  final String tenantId;
  final List<String> roles;

  const AuthSessionDto({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.userId,
    required this.tenantId,
    required this.roles,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) => AuthSessionDto(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String,
        expiresAt: json['expiresAt'] as String,
        userId: json['userId'].toString(),
        tenantId: json['tenantId'].toString(),
        roles: List<String>.from(json['roles'] as List),
      );

  AuthSession toDomain() => AuthSession(
        accessToken: accessToken,
        tokenType: tokenType,
        expiresAt: DateTime.parse(expiresAt),
        userId: userId,
        tenantId: tenantId,
        roles: roles,
      );
}
