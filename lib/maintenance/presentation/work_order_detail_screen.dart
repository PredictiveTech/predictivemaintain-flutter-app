import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../iam/domain/user.dart';
import '../domain/work_order.dart';
import '../domain/work_order_status.dart';
import 'dialogs.dart';
import 'failure_feedback.dart';
import 'maintenance_actions.dart';
import 'maintenance_providers.dart';
import 'maintenance_style.dart';

class WorkOrderDetailScreen extends ConsumerWidget {
  final String workOrderId;

  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void reload() => ref.invalidate(workOrderDetailProvider(workOrderId));

    ref.listen(workOrderActionsProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(
          context,
          state.error!,
          conflictMessage: 'La orden cambió mientras la veías (otra persona la '
              'modificó). Recarga para ver su estado actual.',
          onReload: reload,
        );
      }
    });

    final order = ref.watch(workOrderDetailProvider(workOrderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Orden de trabajo')),
      body: order.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'No se pudo cargar la orden de trabajo: $e',
          onRetry: reload,
        ),
        data: (o) => RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _Info(order: o),
              const SizedBox(height: 16),
              _Actions(order: o),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  final WorkOrder order;

  const _Info({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = order.assignedUserId;
    // Nombre del técnico: el backend solo devuelve su id; se busca en la lista
    // de técnicos y, si no aparece (p. ej. desactivado), se muestra el id.
    final technicians = ref.watch(techniciansProvider).value ?? const <User>[];
    final name = technicians.where((u) => u.id == assigned).map((u) => u.displayName).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.assetName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              WorkOrderStatusChip(order.status),
              SeverityChip(order.severity),
            ]),
            const SizedBox(height: 12),
            Text(order.summary.isEmpty ? 'Sin resumen' : order.summary),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active),
              title: const Text('Alerta vinculada'),
              subtitle: const Text('Ver diagnóstico'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.alertDetail(order.alertId)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.precision_manufacturing),
              title: Text('Activo: ${order.assetName}'),
              subtitle: Text('Código: ${order.assetCode}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.assetDetail(order.assetId)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.engineering),
              title: const Text('Técnico asignado'),
              subtitle: Text(assigned == null ? 'Sin asignar' : (name ?? assigned)),
            ),
            Text('Abierta: ${formatDateTime(order.openedAt)}'),
            const SizedBox(height: 4),
            Text(order.completedAt == null
                ? 'Completada: —'
                : 'Completada: ${formatDateTime(order.completedAt!)}'),
          ],
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  final WorkOrder order;

  const _Actions({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(workOrderActionsProvider).isLoading;
    final actions = ref.read(workOrderActionsProvider.notifier);
    // El backend permite reasignar y cancelar solo mientras no empezó el trabajo.
    final editable =
        order.status == WorkOrderStatus.open || order.status == WorkOrderStatus.assigned;
    if (!editable) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final id = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _TechnicianPicker(current: order.assignedUserId),
                  );
                  if (id != null) await actions.assign(order, id);
                },
          icon: const Icon(Icons.person_add),
          label: Text(order.assignedUserId == null ? 'Asignar técnico' : 'Reasignar técnico'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () async {
                  final reason = await askRequiredText(
                    context,
                    title: 'Cancelar orden',
                    label: 'Motivo de la cancelación',
                    confirmLabel: 'Cancelar orden',
                    maxLength: 2000,
                  );
                  if (reason != null) await actions.cancel(order, reason);
                },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar orden'),
        ),
      ],
    );
  }
}

class _TechnicianPicker extends ConsumerWidget {
  final String? current;

  const _TechnicianPicker({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final technicians = ref.watch(techniciansProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: technicians.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorView(
            message: 'No se pudo cargar la lista de técnicos: $e',
            onRetry: () => ref.invalidate(techniciansProvider),
          ),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No hay técnicos activos')),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Elige un técnico',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    for (final u in list)
                      ListTile(
                        leading: Icon(u.id == current
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                        title: Text(u.displayName),
                        subtitle: Text(u.email),
                        onTap: () => Navigator.pop(context, u.id),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
