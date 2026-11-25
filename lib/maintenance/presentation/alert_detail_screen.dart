import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../domain/alert.dart';
import '../domain/alert_diagnostic.dart';
import '../domain/alert_status.dart';
import 'dialogs.dart';
import 'failure_feedback.dart';
import 'maintenance_actions.dart';
import 'maintenance_providers.dart';
import 'maintenance_style.dart';

class AlertDetailScreen extends ConsumerWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void reload() => ref.invalidate(alertDetailProvider(alertId));

    ref.listen(alertActionsProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(
          context,
          state.error!,
          conflictMessage: 'La alerta cambió (otra persona la modificó o ya no '
              'está en revisión). Recarga para ver su estado actual.',
          onReload: reload,
        );
      }
    });
    ref.listen(workOrderActionsProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(
          context,
          state.error!,
          conflictMessage: 'No se pudo generar la orden: la alerta no está '
              'confirmada o ya tiene una orden de trabajo.',
          onReload: reload,
        );
      }
    });

    final alert = ref.watch(alertDetailProvider(alertId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de alerta')),
      body: alert.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'No se pudo cargar la alerta: $e',
          onRetry: reload,
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _Header(alert: a),
              const SizedBox(height: 16),
              _DiagnosticCard(diagnostic: a.diagnostic),
              const SizedBox(height: 16),
              _Actions(alert: a),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Alert alert;

  const _Header({required this.alert});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.assetName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Código: ${alert.assetCode}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: [
                SeverityChip(alert.severity),
                AlertStatusChip(alert.status),
              ]),
              const SizedBox(height: 12),
              Text('Generada: ${formatDateTime(alert.raisedAt)}'),
              if (alert.discardReason != null) ...[
                const SizedBox(height: 8),
                Text('Motivo del descarte: ${alert.discardReason}'),
              ],
            ],
          ),
        ),
      );
}

class _DiagnosticCard extends StatelessWidget {
  final AlertDiagnostic? diagnostic;

  const _DiagnosticCard({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    final d = diagnostic;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagnóstico',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (d == null)
              const Text('Esta alerta no tiene datos de diagnóstico.')
            else ...[
              Text('Métrica: ${d.metric}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Valor observado: ${formatNumber(d.observedValue)} ${d.unit}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _outOfBounds(d) ? Colors.red.shade700 : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rango permitido: ${formatNumber(d.lowerBound)} – '
                '${formatNumber(d.upperBound)} ${d.unit}',
              ),
              if (_outOfBounds(d))
                Text(
                  d.observedValue > d.upperBound
                      ? 'Supera el límite superior en ${formatNumber(d.observedValue - d.upperBound)} ${d.unit}'
                      : 'Está por debajo del límite inferior en ${formatNumber(d.lowerBound - d.observedValue)} ${d.unit}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              const SizedBox(height: 8),
              Text('Medido: ${formatDateTime(d.measuredAt)}',
                  style: TextStyle(color: Colors.grey.shade700)),
            ],
          ],
        ),
      ),
    );
  }

  static bool _outOfBounds(AlertDiagnostic d) =>
      d.observedValue > d.upperBound || d.observedValue < d.lowerBound;
}

class _Actions extends ConsumerWidget {
  final Alert alert;

  const _Actions({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(alertActionsProvider).isLoading ||
        ref.watch(workOrderActionsProvider).isLoading;
    final alertActions = ref.read(alertActionsProvider.notifier);
    final confirmed = alert.status == AlertStatus.confirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alert.status == AlertStatus.inReview) ...[
          FilledButton.icon(
            onPressed: busy ? null : () => alertActions.confirm(alert),
            icon: const Icon(Icons.check),
            label: const Text('Confirmar alerta'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final reason = await askRequiredText(
                      context,
                      title: 'Descartar alerta',
                      label: 'Motivo del descarte',
                      confirmLabel: 'Descartar',
                    );
                    if (reason != null) await alertActions.discard(alert, reason);
                  },
            icon: const Icon(Icons.close),
            label: const Text('Descartar alerta'),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.tonalIcon(
          // Solo se puede generar la orden de una alerta confirmada.
          onPressed: busy || !confirmed
              ? null
              : () async {
                  final ok = await askConfirmation(
                    context,
                    title: 'Generar orden de trabajo',
                    message: 'Se creará una orden abierta y sin asignar para '
                        '${alert.assetName}. Podrás asignar un técnico desde su detalle.',
                    confirmLabel: 'Generar',
                  );
                  if (!ok || !context.mounted) return;
                  final order = await ref.read(workOrderActionsProvider.notifier).create(alert);
                  if (order != null && context.mounted) {
                    context.push(AppRoutes.workOrderDetail(order.id));
                  }
                },
          icon: const Icon(Icons.assignment_add),
          label: const Text('Generar orden de trabajo'),
        ),
        if (!confirmed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Disponible cuando la alerta esté confirmada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
