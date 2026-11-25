import 'subscription.dart';

abstract interface class SubscriptionRepository {
  Future<Subscription> getSubscription();
  Future<List<SubscriptionPlan>> getPlans();

  /// Cambia de plan. 409 (`ConflictFailure`) si los activos en uso superan el
  /// límite del plan destino.
  Future<Subscription> changePlan(String planId);
}
