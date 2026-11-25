import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/work_order.dart';
import '../domain/work_order_status.dart';
import 'maintenance_providers.dart';

class WorkOrdersScreen extends ConsumerWidget {
  const WorkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reintentar muestra de nuevo el spinner, igual que antes.
    return ref.watch(workOrdersProvider).when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudieron cargar las órdenes de trabajo: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(workOrdersProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No hay órdenes de trabajo'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) => _WorkOrderCard(order: items[index]),
        );
      },
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder order;

  const _WorkOrderCard({required this.order});

  static Color _statusColor(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.pending => Colors.orange,
        WorkOrderStatus.inProgress => Colors.blue,
        WorkOrderStatus.completed => Colors.green,
      };

  static String _statusLabel(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.pending => 'Pendiente',
        WorkOrderStatus.inProgress => 'En progreso',
        WorkOrderStatus.completed => 'Completada',
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final technician = order.assignedUserId;
    return Card(
      child: ListTile(
        title: Text(order.assetName),
        subtitle: technician == null ? null : Text('Técnico: $technician'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              _statusLabel(order.status),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
