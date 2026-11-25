import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/failure.dart';
import '../../core/error/retry.dart';
import '../application/change_plan_use_case.dart';
import '../domain/subscription.dart';

final subscriptionProvider = FutureProvider.autoDispose<Subscription>(
  (ref) => ref.watch(getSubscriptionUseCaseProvider)(),
  retry: noRetry,
);

final plansProvider = FutureProvider.autoDispose<List<SubscriptionPlan>>(
  (ref) => ref.watch(getPlansUseCaseProvider)(),
  retry: noRetry,
);

/// Cambio de plan. Un downgrade bloqueado no es un error: queda como
/// [PlanDowngradeBlocked] en el estado de data.
class ChangePlanController extends AsyncNotifier<ChangePlanResult?> {
  @override
  ChangePlanResult? build() => null;

  Future<void> change(Subscription current, SubscriptionPlan target) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(changePlanUseCaseProvider)(current, target);
      state = AsyncData(result);
      if (result is PlanChanged) ref.invalidate(subscriptionProvider);
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
    }
  }
}

final changePlanProvider =
    AsyncNotifierProvider.autoDispose<ChangePlanController, ChangePlanResult?>(
        ChangePlanController.new);
