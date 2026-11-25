import '../../core/domain/paged_result.dart';
import '../../core/network/api_client.dart';
import '../../maintenance/infrastructure/paged_response_dto.dart';
import '../domain/user.dart';
import '../domain/user_repository.dart';
import 'user_dto.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient _api;

  UserRepositoryImpl(this._api);

  @override
  Future<PagedResult<User>> getUsers({String? role, bool? active, int page = 0}) async {
    final json = await _api.get('/users', query: {
      'role': role,
      'active': active?.toString(),
      'page': page == 0 ? null : '$page',
    });
    return parseResponse(
      () => PagedResponseDto.fromJson(json as Map<String, dynamic>, UserDto.fromJson)
          .toDomain((dto) => dto.toDomain()),
    );
  }

  User _user(dynamic json) =>
      parseResponse(() => UserDto.fromJson(json as Map<String, dynamic>).toDomain());

  @override
  Future<User> getMe() async => _user(await _api.get('/users/me'));

  @override
  Future<User> updateDisplayName(String displayName) async =>
      _user(await _api.patch('/users/me', body: {'displayName': displayName}));
}
