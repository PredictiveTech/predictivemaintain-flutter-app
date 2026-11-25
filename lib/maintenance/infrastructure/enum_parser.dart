/// Convierte un valor del backend (p. ej. `IN_REVIEW`) al enum de dominio
/// cuyo nombre coincide ignorando mayúsculas y guiones bajos (`inReview`).
T parseEnum<T extends Enum>(List<T> values, Object? raw) {
  final normalized = _normalize(raw.toString());
  for (final value in values) {
    if (_normalize(value.name) == normalized) return value;
  }
  throw FormatException('Valor no reconocido para $T: $raw');
}

String _normalize(String s) => s.replaceAll('_', '').toLowerCase();

/// Inverso de [parseEnum]: `inReview` -> `IN_REVIEW`.
String apiName(Enum value) => value.name
    .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}')
    .toUpperCase();
