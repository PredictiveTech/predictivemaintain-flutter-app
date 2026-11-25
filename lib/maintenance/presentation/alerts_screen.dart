import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../core/presentation/widgets/filter_chips_row.dart';
import '../domain/alert.dart';
import 'maintenance_providers.dart';
import 'maintenance_style.dart';
import 'paged_list_view.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 8),
        FilterChipsRow(
          title: 'Estado',
          options: alertStatusOptions,
          labelOf: alertStatusLabel,
          selected: ref.watch(alertStatusFilterProvider),
          onSelected: ref.read(alertStatusFilterProvider.notifier).select,
        ),
        FilterChipsRow(
          title: 'Severidad',
          options: alertSeverityOptions,
          labelOf: severityLabel,
          selected: ref.watch(alertSeverityFilterProvider),
          onSelected: ref.read(alertSeverityFilterProvider.notifier).select,
        ),
        Expanded(
          // Reintentar y cambiar de filtro muestran de nuevo el spinner.
          child: ref.watch(alertsProvider).when(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: 'No se pudieron cargar las alertas: $e',
                  onRetry: () => ref.invalidate(alertsProvider),
                ),
                data: (data) => PagedListBody<Alert>(
                  data: data,
                  items: data.items,
                  emptyMessage: 'No hay alertas',
                  itemBuilder: (alert) => _AlertCard(alert: alert),
                  onLoadMore: () => ref.read(alertsProvider.notifier).loadMore(),
                ),
              ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(alert.severity);
    return Card(
      child: ListTile(
        onTap: () => context.push(AppRoutes.alertDetail(alert.id)),
        title: Text(alert.assetName),
        subtitle: Text('Estado: ${alertStatusLabel(alert.status)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              severityLabel(alert.severity),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
