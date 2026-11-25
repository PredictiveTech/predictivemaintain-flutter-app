import 'package:flutter/material.dart';

import '../../core/presentation/widgets/status_chip.dart';
import '../domain/alert_status.dart';
import '../domain/severity.dart';
import '../domain/work_order_status.dart';

Color severityColor(Severity severity) => switch (severity) {
      Severity.critical => Colors.red,
      Severity.warning => Colors.amber.shade800,
      Severity.high => Colors.orange,
      Severity.medium => Colors.yellow.shade800,
      Severity.low => Colors.blue,
    };

String severityLabel(Severity severity) => switch (severity) {
      Severity.critical => 'Crítica',
      Severity.warning => 'Advertencia',
      Severity.high => 'Alta',
      Severity.medium => 'Media',
      Severity.low => 'Baja',
    };

String alertStatusLabel(AlertStatus status) => switch (status) {
      AlertStatus.inReview => 'En revisión',
      AlertStatus.confirmed => 'Confirmada',
      AlertStatus.discarded => 'Descartada',
      AlertStatus.resolved => 'Resuelta',
    };

Color alertStatusColor(AlertStatus status) => switch (status) {
      AlertStatus.inReview => Colors.blueGrey,
      AlertStatus.confirmed => Colors.red.shade700,
      AlertStatus.discarded => Colors.grey.shade700,
      AlertStatus.resolved => Colors.green.shade700,
    };

String workOrderStatusLabel(WorkOrderStatus status) => switch (status) {
      WorkOrderStatus.open => 'Abierta',
      WorkOrderStatus.assigned => 'Asignada',
      WorkOrderStatus.inProgress => 'En progreso',
      WorkOrderStatus.completed => 'Completada',
      WorkOrderStatus.cancelled => 'Cancelada',
    };

Color workOrderStatusColor(WorkOrderStatus status) => switch (status) {
      WorkOrderStatus.open => Colors.orange,
      WorkOrderStatus.assigned => Colors.indigo,
      WorkOrderStatus.inProgress => Colors.blue,
      WorkOrderStatus.completed => Colors.green,
      WorkOrderStatus.cancelled => Colors.grey,
    };

class SeverityChip extends StatelessWidget {
  final Severity severity;

  const SeverityChip(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = severityColor(severity);
    return StatusChip(
        label: severityLabel(severity), color: c, background: c.withValues(alpha: 0.12), dot: true);
  }
}

class AlertStatusChip extends StatelessWidget {
  final AlertStatus status;

  const AlertStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = alertStatusColor(status);
    return StatusChip(
        label: alertStatusLabel(status), color: c, background: c.withValues(alpha: 0.12));
  }
}

class WorkOrderStatusChip extends StatelessWidget {
  final WorkOrderStatus status;

  const WorkOrderStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = workOrderStatusColor(status);
    return StatusChip(
        label: workOrderStatusLabel(status), color: c, background: c.withValues(alpha: 0.12));
  }
}
