import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../maintenance/presentation/failure_feedback.dart';
import '../application/change_plan_use_case.dart';
import '../domain/subscription.dart';
import 'subscription_providers.dart';

/// Lista de planes y cambio de plan (US-17).
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(changePlanProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(context, state.error!,
            conflictMessage: 'No se pudo cambiar de plan.', onReload: () {});
      }
      final result = state.value;
      if (result is PlanDowngradeBlocked) {
        final n = result.assetsToDeactivate;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No se puede bajar de plan'),
            content: Text('Tienes más activos de los que admite ese plan. Debes dar de baja '
                '$n ${n == 1 ? 'activo' : 'activos'} antes de cambiar.'),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
            ],
          ),
        );
      } else if (result is PlanChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Plan actualizado: ${result.subscription.plan.name}')));
      }
    });

    final subscription = ref.watch(subscriptionProvider);
    final plans = ref.watch(plansProvider);
    final changing = ref.watch(changePlanProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'No se pudieron cargar los planes: $e',
          onRetry: () => ref.invalidate(plansProvider),
        ),
        data: (list) {
          final current = subscription.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final plan in list)
                _PlanTile(
                  plan: plan,
                  isCurrent: plan.id == current?.plan.id,
                  enabled: !changing && current != null,
                  onSelect: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Cambiar al plan ${plan.name}'),
                        content: Text('${plan.assetLimit} activos · '
                            '${formatNumber(plan.amount)} ${plan.currency}. Se emitirá una factura.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Volver')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Cambiar')),
                        ],
                      ),
                    );
                    if (ok == true && current != null) {
                      await ref.read(changePlanProvider.notifier).change(current, plan);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback onSelect;

  const _PlanTile({
    required this.plan,
    required this.isCurrent,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Card(
        shape: isCurrent
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2))
            : null,
        child: ListTile(
          title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Hasta ${plan.assetLimit} activos · '
              '${formatNumber(plan.amount)} ${plan.currency}'),
          trailing: isCurrent
              ? const Chip(label: Text('Plan actual'))
              : FilledButton.tonal(
                  onPressed: enabled ? onSelect : null, child: const Text('Elegir')),
        ),
      );
}
