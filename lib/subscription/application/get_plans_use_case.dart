import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';

class GetPlansUseCase {
  final SubscriptionRepository _repository;

  GetPlansUseCase(this._repository);

  /// Planes ordenados de menor a mayor límite de activos.
  Future<List<SubscriptionPlan>> call() async {
    final plans = await _repository.getPlans();
    return [...plans]..sort((a, b) => a.assetLimit.compareTo(b.assetLimit));
  }
}
