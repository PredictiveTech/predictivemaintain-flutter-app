import '../error/failure.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// `24/11/2026 14:05` en hora local.
String formatDateTime(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.day)}/${_two(l.month)}/${l.year} ${_two(l.hour)}:${_two(l.minute)}';
}

String formatNumber(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// Mensaje para el usuario cuando falla una acción (confirmar, asignar…).
/// Los 409 los trata cada pantalla porque ofrecen recargar.
String describeActionFailure(Object e) {
  if (e is Failure) {
    return switch (e) {
      NetworkFailure() => 'No se pudo completar la acción. Revisa tu conexión.',
      ValidationFailure() => e.serverMessage ?? e.message,
      UnauthorizedFailure() => 'Tu sesión expiró. Vuelve a iniciar sesión.',
      ConflictFailure() => e.serverMessage ?? 'La operación no es válida en el estado actual.',
      ServerFailure() when e.statusCode == 403 => 'No tienes permisos para esta acción.',
      ServerFailure() => e.serverMessage ?? 'El servidor no pudo completar la acción (${e.message}).',
      MalformedResponseFailure() => 'La respuesta del servidor no tiene el formato esperado.',
    };
  }
  return 'No se pudo completar la acción.';
}
