import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/alert.dart';
import '../domain/alert_status.dart';
import '../domain/severity.dart';
import 'maintenance_providers.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reintentar muestra de nuevo el spinner, igual que antes.
    return ref.watch(alertsProvider).when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudieron cargar las alertas: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(alertsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No hay alertas'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) => _AlertCard(alert: items[index]),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  static Color _severityColor(Severity severity) => switch (severity) {
        Severity.critical => Colors.red,
        Severity.warning => Colors.amber.shade800,
        Severity.high => Colors.orange,
        Severity.medium => Colors.yellow.shade800,
        Severity.low => Colors.blue,
      };

  static String _severityLabel(Severity severity) => switch (severity) {
        Severity.critical => 'Crítica',
        Severity.warning => 'Advertencia',
        Severity.high => 'Alta',
        Severity.medium => 'Media',
        Severity.low => 'Baja',
      };

  static String _statusLabel(AlertStatus status) => switch (status) {
        AlertStatus.inReview => 'En revisión',
        AlertStatus.confirmed => 'Confirmada',
        AlertStatus.discarded => 'Descartada',
        AlertStatus.resolved => 'Resuelta',
      };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    return Card(
      child: ListTile(
        title: Text(alert.assetName),
        subtitle: Text('Estado: ${_statusLabel(alert.status)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              _severityLabel(alert.severity),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
