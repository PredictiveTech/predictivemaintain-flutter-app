import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../application/compare_assets_use_case.dart';
import '../domain/comparison_row.dart';
import '../domain/report_range.dart';
import 'failure_feedback.dart';
import 'maintenance_providers.dart';
import 'report_providers.dart';
import 'report_range_picker.dart';

/// Reporte comparativo entre activos (US-15, US-16).
class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  final _selected = <String>{};
  late ReportRange _range = ReportRange.lastDays(30, DateTime.now());

  // Rango y selección con los que se generó la tabla (el CSV exporta lo mismo).
  List<String> _generatedIds = const [];
  ReportRange? _generatedRange;

  Future<void> _generate() async {
    final ids = _selected.toList();
    final range = _range;
    await ref.read(comparisonProvider.notifier).generate(ids, range);
    if (!ref.read(comparisonProvider).hasError) {
      _generatedIds = ids;
      _generatedRange = range;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(exportProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(context, state.error!,
            conflictMessage: 'No se pudo exportar.', onReload: () {});
      }
    });
    final assets = ref.watch(assetsProvider);
    final result = ref.watch(comparisonProvider);
    final exporting = ref.watch(exportProvider).isLoading;
    final canExport = result.value != null && _generatedRange != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar activos'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: exporting || !canExport
                ? null
                : () => ref.read(exportProvider.notifier).export(_generatedIds, _generatedRange!),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Activos (1 a 20)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          assets.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => ErrorView(
              message: 'No se pudieron cargar los activos: $e',
              onRetry: () => ref.invalidate(assetsProvider),
              inline: true,
            ),
            data: (list) => Column(
              children: [
                for (final a in list)
                  CheckboxListTile(
                    dense: true,
                    value: _selected.contains(a.id),
                    title: Text(a.name),
                    subtitle: Text(a.code),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        if (_selected.length < CompareAssetsUseCase.maxAssets) _selected.add(a.id);
                      } else {
                        _selected.remove(a.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ReportRangePicker(range: _range, onChanged: (r) => setState(() => _range = r)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _selected.isEmpty || result.isLoading ? null : _generate,
            icon: const Icon(Icons.compare_arrows),
            label: Text(_selected.isEmpty
                ? 'Selecciona al menos un activo'
                : 'Generar reporte (${_selected.length})'),
          ),
          const SizedBox(height: 16),
          result.when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              message: 'No se pudo generar el reporte: $e',
              onRetry: _generate,
              inline: true,
            ),
            data: (rows) => rows == null ? const SizedBox.shrink() : _ComparisonTable(rows: rows),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<ComparisonRow> rows;

  const _ComparisonTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Center(child: Text('Sin datos para el rango elegido'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Activo')),
          DataColumn(label: Text('Alertas'), numeric: true),
          DataColumn(label: Text('Críticas'), numeric: true),
          DataColumn(label: Text('Paros'), numeric: true),
          DataColumn(label: Text('Tiempo detenido')),
          DataColumn(label: Text('Disponibilidad'), numeric: true),
        ],
        rows: [
          for (final r in rows)
            DataRow(cells: [
              DataCell(Text('${r.assetName}\n${r.assetCode}')),
              DataCell(Text('${r.alerts}')),
              DataCell(Text('${r.criticalAlerts}')),
              DataCell(Text('${r.stops}')),
              DataCell(Text(formatDuration(r.downtime))),
              DataCell(Text('${formatNumber(r.availabilityPercent)} %')),
            ]),
        ],
      ),
    );
  }
}
