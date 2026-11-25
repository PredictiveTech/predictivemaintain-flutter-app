import '../../core/error/failure.dart';
import '../domain/user.dart';
import '../domain/user_repository.dart';

/// Cambia el nombre visible del usuario (US-23).
class UpdateDisplayNameUseCase {
  final UserRepository _repository;

  UpdateDisplayNameUseCase(this._repository);

  Future<User> call(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const ValidationFailure('El nombre no puede estar vacío.');
    }
    return _repository.updateDisplayName(name);
  }
}
