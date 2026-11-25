import '../domain/user.dart';
import '../domain/user_repository.dart';

/// Técnicos activos de la empresa, para elegir a quién asignar una orden.
/// Recorre todas las páginas (el selector necesita la lista completa).
class GetTechniciansUseCase {
  final UserRepository _repository;

  GetTechniciansUseCase(this._repository);

  Future<List<User>> call() async {
    final all = <User>[];
    var page = 0;
    while (true) {
      final result = await _repository.getUsers(
        role: UserRoles.technician,
        active: true,
        page: page,
      );
      all.addAll(result.items);
      page++;
      if (page >= result.totalPages) return all;
    }
  }
}
