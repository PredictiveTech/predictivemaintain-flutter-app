import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../core/presentation/widgets/status_chip.dart';
import '../domain/subscription.dart';
import 'subscription_providers.dart';

/// Consumo actual de la suscripción (US-18).
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(subscriptionProvider).when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: 'No se pudo cargar la suscripción: $e',
            onRetry: () => ref.invalidate(subscriptionProvider),
          ),
          data: (s) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(subscriptionProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (s.capacity.nearLimit) _NearLimitBanner(capacity: s.capacity),
                if (s.expiry.expired || s.expiry.expiresSoon || !s.monitoringAllowed)
                  _ExpiryBanner(subscription: s),
                _PlanCard(subscription: s),
                const SizedBox(height: 12),
                _CapacityCard(capacity: s.capacity),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.plans),
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Cambiar de plan'),
                ),
              ],
            ),
          ),
        );
  }
}

class _NearLimitBanner extends StatelessWidget {
  final Capacity capacity;

  const _NearLimitBanner({required this.capacity});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.amber.shade100,
        child: ListTile(
          leading: Icon(Icons.warning_amber, color: Colors.amber.shade900),
          title: const Text('Cerca del límite de tu plan'),
          subtitle: Text(
              'Usas ${capacity.used} de ${capacity.limit} activos. Considera pasar a un plan mayor.'),
        ),
      );
}

class _ExpiryBanner extends StatelessWidget {
  final Subscription subscription;

  const _ExpiryBanner({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final e = subscription.expiry;
    final text = e.expired || !subscription.monitoringAllowed
        ? 'La suscripción venció: el monitoreo está suspendido.'
        : 'La suscripción vence en ${e.daysRemaining} ${e.daysRemaining == 1 ? 'día' : 'días'}.';
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: Icon(Icons.event_busy, color: Colors.red.shade700),
        title: Text(text),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Subscription subscription;

  const _PlanCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final plan = subscription.plan;
    final (label, color) = switch (subscription.status) {
      SubscriptionStatus.active => ('Activa', Colors.green.shade700),
      SubscriptionStatus.suspended => ('Suspendida', Colors.orange.shade800),
      SubscriptionStatus.cancelled => ('Cancelada', Colors.grey.shade700),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Plan ${plan.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                StatusChip(label: label, color: color, background: color.withValues(alpha: 0.12), dot: true),
              ],
            ),
            const SizedBox(height: 4),
            Text('${formatNumber(plan.amount)} ${plan.currency}'),
            const Divider(height: 24),
            Text('Fecha de renovación: ${formatDate(subscription.endsAt)}'),
            Text('Días restantes: ${subscription.expiry.daysRemaining}'),
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final Capacity capacity;

  const _CapacityCard({required this.capacity});

  @override
  Widget build(BuildContext context) {
    final fraction = capacity.limit == 0 ? 0.0 : (capacity.used / capacity.limit).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activos usados', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: capacity.nearLimit ? Colors.amber.shade800 : null,
            ),
            const SizedBox(height: 8),
            Text('${capacity.used} de ${capacity.limit} (${formatNumber(capacity.usagePercent)} %) · '
                '${capacity.available} disponibles'),
          ],
        ),
      ),
    );
  }
}
