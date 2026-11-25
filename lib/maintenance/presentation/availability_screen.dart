import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../domain/availability_report.dart';
import '../domain/report_range.dart';
import 'failure_feedback.dart';
import 'report_providers.dart';
import 'report_range_picker.dart';

/// Historial de fallas y disponibilidad de un activo (US-14, US-16).
class AvailabilityScreen extends ConsumerStatefulWidget {
  final String assetId;

  const AvailabilityScreen({super.key, required this.assetId});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  // Por defecto, los últimos 30 días.
  late ReportRange _range = ReportRange.lastDays(30, DateTime.now());

  AvailabilityQuery get _query => (assetId: widget.assetId, range: _range);

  @override
  Widget build(BuildContext context) {
    ref.watch(exportProvider);
    ref.listen(exportProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(context, state.error!,
            conflictMessage: 'No se pudo exportar.', onReload: () {});
      }
    });
    final exporting = ref.watch(exportProvider).isLoading;
    final report = ref.watch(availabilityReportProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: exporting
                ? null
                : () => ref.read(exportProvider.notifier).export([widget.assetId], _range),
            icon: exporting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReportRangePicker(range: _range, onChanged: (r) => setState(() => _range = r)),
          const SizedBox(height: 16),
          report.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorView(
              message: 'No se pudo cargar el reporte: $e',
              onRetry: () => ref.invalidate(availabilityReportProvider(_query)),
              inline: true,
            ),
            data: (r) => _ReportBody(report: r),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final AvailabilityReport report;

  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final percent = report.availabilityPercent;
    final color = percent >= 99
        ? Colors.green.shade700
        : percent >= 95
            ? Colors.orange.shade800
            : Colors.red.shade700;
    final downtimes = report.downtimes;
    final alerts = report.events.where((e) => e.type == AssetEventType.alert).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.assetCode, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('${formatNumber(percent)} %',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
                const Text('Disponibilidad'),
                const SizedBox(height: 12),
                Text('Tiempo total detenido: ${formatDuration(report.downtime)}'),
                Text('Período analizado: ${formatDuration(report.period)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!report.hasEvents)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Sin alertas ni paros en el período')),
          )
        else ...[
          Text('Paros (${downtimes.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (downtimes.isEmpty) const Text('No hubo paros en el período'),
          for (final e in downtimes) _DowntimeTile(event: e),
          const SizedBox(height: 16),
          Text('Alertas (${alerts.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (alerts.isEmpty) const Text('No hubo alertas en el período'),
          for (final e in alerts) _AlertEventTile(event: e),
        ],
      ],
    );
  }
}

class _DowntimeTile extends StatelessWidget {
  final AssetEvent event;

  const _DowntimeTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final end = event.endedAt;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.power_off),
        title: Text('${formatDateTime(event.occurredAt)} → ${end == null ? 'en curso' : formatDateTime(end)}'),
        subtitle: Text(end == null
            ? 'Paro en curso'
            : 'Duración: ${formatDuration(end.difference(event.occurredAt))}'),
      ),
    );
  }
}

class _AlertEventTile extends StatelessWidget {
  final AssetEvent event;

  const _AlertEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final severity = event.severity?.toUpperCase();
    final color = severity == 'CRITICAL' ? Colors.red : Colors.amber.shade800;
    return Card(
      child: ListTile(
        leading: Icon(Icons.notifications_active, color: color),
        title: Text(formatDateTime(event.occurredAt)),
        subtitle: Text([
          if (event.severity != null) 'Severidad: ${event.severity}',
          if (event.status != null) 'Estado: ${event.status}',
        ].join(' · ')),
      ),
    );
  }
}
