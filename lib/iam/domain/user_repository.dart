import '../../core/domain/paged_result.dart';
import 'user.dart';

abstract final class UserRoles {
  static const technician = 'TECHNICIAN';
}

abstract interface class UserRepository {
  Future<PagedResult<User>> getUsers({String? role, bool? active, int page = 0});
}
