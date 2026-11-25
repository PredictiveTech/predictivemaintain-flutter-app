import '../../core/error/failure.dart';

/// Rango de fechas de un reporte. El backend exige from < to, máx. 366 días y
/// que `to` no pase de ahora.
class ReportRange {
  static const maxDays = 366;

  final DateTime from;
  final DateTime to;

  const ReportRange(this.from, this.to);

  factory ReportRange.lastDays(int days, DateTime now) =>
      ReportRange(now.subtract(Duration(days: days)), now);

  /// Desde el inicio de [firstDay] hasta el final de [lastDay] (hora local).
  factory ReportRange.ofDays(DateTime firstDay, DateTime lastDay) => ReportRange(
        DateTime(firstDay.year, firstDay.month, firstDay.day),
        DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
      );

  /// Recorta `to` a [now] y valida las reglas del backend.
  ReportRange validated(DateTime now) {
    final end = to.isAfter(now) ? now : to;
    if (!from.isBefore(end)) {
      throw const ValidationFailure('El rango de fechas no es válido.');
    }
    if (end.difference(from) > const Duration(days: maxDays)) {
      throw const ValidationFailure('El rango no puede superar 366 días.');
    }
    return ReportRange(from, end);
  }

  @override
  bool operator ==(Object other) =>
      other is ReportRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
