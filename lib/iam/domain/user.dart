/// Usuario devuelto por GET /api/v1/users/me.
class User {
  final String id;
  final String tenantId;
  final String email;
  final String displayName;
  final bool active;
  final List<String> roles;

  const User({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.displayName,
    required this.active,
    required this.roles,
  });
}
