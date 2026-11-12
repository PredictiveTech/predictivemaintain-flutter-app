import '../domain/user.dart';

class UserDto {
  final String id;
  final String tenantId;
  final String email;
  final String displayName;
  final bool active;
  final List<String> roles;

  const UserDto({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.displayName,
    required this.active,
    required this.roles,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'].toString(),
        tenantId: json['tenantId'].toString(),
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        active: json['active'] as bool,
        roles: List<String>.from(json['roles'] as List),
      );

  User toDomain() => User(
        id: id,
        tenantId: tenantId,
        email: email,
        displayName: displayName,
        active: active,
        roles: roles,
      );
}
