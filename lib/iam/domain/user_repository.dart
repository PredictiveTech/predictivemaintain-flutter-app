import '../../core/domain/paged_result.dart';
import 'user.dart';

abstract final class UserRoles {
  static const technician = 'TECHNICIAN';
  static const manager = 'MAINTENANCE_MANAGER';
  static const operator = 'OPERATOR';
}

abstract interface class UserRepository {
  Future<PagedResult<User>> getUsers({String? role, bool? active, int page = 0});

  Future<User> getMe();
  Future<User> updateDisplayName(String displayName);
}
