import '../domain/user.dart';
import '../domain/user_repository.dart';

class GetProfileUseCase {
  final UserRepository _repository;

  GetProfileUseCase(this._repository);

  Future<User> call() => _repository.getMe();
}
