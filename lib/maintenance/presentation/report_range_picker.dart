import 'package:flutter/material.dart';

import '../../core/presentation/format.dart';
import '../domain/report_range.dart';

/// Muestra el rango actual y abre el selector de fechas del sistema.
class ReportRangePicker extends StatelessWidget {
  final ReportRange range;
  final ValueChanged<ReportRange> onChanged;

  const ReportRangePicker({super.key, required this.range, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(start: range.from, end: range.to),
      helpText: 'Rango del reporte (máx. 366 días)',
    );
    if (picked != null) onChanged(ReportRange.ofDays(picked.start, picked.end));
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.date_range),
        label: Text('${formatDate(range.from)} – ${formatDate(range.to)}'),
      );
}
