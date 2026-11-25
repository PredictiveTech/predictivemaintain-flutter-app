/// Jerarquía de errores compartida por todas las capas.
///
/// [message] es el texto técnico corto (p. ej. `HTTP 500` o el `toString()`
/// de la excepción original); la presentación decide cómo mostrarlo.
sealed class Failure implements Exception {
  final String message;

  /// Código HTTP que originó el error, si lo hubo.
  final int? statusCode;

  /// Campo `message` del cuerpo de error del backend, si venía.
  final String? serverMessage;

  const Failure(this.message, {this.statusCode, this.serverMessage});

  @override
  String toString() => message;
}

/// Sin conexión, timeout o cualquier error de transporte.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// HTTP 401: token ausente, inválido o expirado.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message,
      {super.statusCode = 401, super.serverMessage});
}

/// HTTP 400/422: el backend rechazó los datos enviados.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.statusCode, super.serverMessage});
}

/// HTTP 409: el recurso cambió (versión desactualizada) o la operación no es
/// válida en su estado actual.
class ConflictFailure extends Failure {
  const ConflictFailure(super.message,
      {super.statusCode = 409, super.serverMessage});
}

/// Cualquier otra respuesta no exitosa (403, 404, 5xx…).
class ServerFailure extends Failure {
  const ServerFailure(super.message,
      {required int super.statusCode, super.serverMessage});
}

/// Respuesta exitosa cuyo cuerpo no tiene el formato esperado.
class MalformedResponseFailure extends Failure {
  const MalformedResponseFailure(super.message);
}
