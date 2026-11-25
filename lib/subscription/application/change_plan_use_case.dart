import '../../core/error/failure.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';

sealed class ChangePlanResult {
  const ChangePlanResult();
}

class PlanChanged extends ChangePlanResult {
  final Subscription subscription;
  const PlanChanged(this.subscription);
}

/// El plan destino no alcanza para los activos en uso (409).
class PlanDowngradeBlocked extends ChangePlanResult {
  /// Cuántos activos habría que dar de baja antes de bajar de plan.
  final int assetsToDeactivate;
  const PlanDowngradeBlocked(this.assetsToDeactivate);
}

/// Cambio de plan (US-17). El backend no informa cuántos activos sobran en el
/// 409, así que se calcula con la capacidad que el usuario estaba viendo:
/// activos en uso − límite del plan destino.
class ChangePlanUseCase {
  final SubscriptionRepository _repository;

  ChangePlanUseCase(this._repository);

  Future<ChangePlanResult> call(Subscription current, SubscriptionPlan target) async {
    if (target.id == current.plan.id) return PlanChanged(current);
    try {
      return PlanChanged(await _repository.changePlan(target.id));
    } on ConflictFailure {
      final excess = current.capacity.used - target.assetLimit;
      return PlanDowngradeBlocked(excess < 1 ? 1 : excess);
    }
  }
}
