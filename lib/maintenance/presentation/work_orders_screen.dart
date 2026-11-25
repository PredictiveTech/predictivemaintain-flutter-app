import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../core/presentation/widgets/filter_chips_row.dart';
import '../domain/work_order.dart';
import 'maintenance_providers.dart';
import 'maintenance_style.dart';
import 'paged_list_view.dart';

class WorkOrdersScreen extends ConsumerWidget {
  const WorkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severity = ref.watch(workOrderSeverityFilterProvider);
    return Column(
      children: [
        const SizedBox(height: 8),
        FilterChipsRow(
          title: 'Estado',
          options: workOrderStatusOptions,
          labelOf: workOrderStatusLabel,
          selected: ref.watch(workOrderStatusFilterProvider),
          onSelected: ref.read(workOrderStatusFilterProvider.notifier).select,
        ),
        FilterChipsRow(
          title: 'Severidad',
          options: alertSeverityOptions,
          labelOf: severityLabel,
          selected: severity,
          onSelected: ref.read(workOrderSeverityFilterProvider.notifier).select,
        ),
        Expanded(
          child: ref.watch(workOrdersProvider).when(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: 'No se pudieron cargar las órdenes de trabajo: $e',
                  onRetry: () => ref.invalidate(workOrdersProvider),
                ),
                data: (data) => PagedListBody<WorkOrder>(
                  data: data,
                  items: severity == null
                      ? data.items
                      : data.items.where((o) => o.severity == severity).toList(),
                  emptyMessage: 'No hay órdenes de trabajo',
                  itemBuilder: (order) => _WorkOrderCard(order: order),
                  onLoadMore: () => ref.read(workOrdersProvider.notifier).loadMore(),
                ),
              ),
        ),
      ],
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder order;

  const _WorkOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = workOrderStatusColor(order.status);
    final technician = order.assignedUserId;
    return Card(
      child: ListTile(
        onTap: () => context.push(AppRoutes.workOrderDetail(order.id)),
        title: Text(order.assetName),
        subtitle: technician == null ? null : Text('Técnico: $technician'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              workOrderStatusLabel(order.status),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
