import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';

class GetSubscriptionUseCase {
  final SubscriptionRepository _repository;

  GetSubscriptionUseCase(this._repository);

  Future<Subscription> call() => _repository.getSubscription();
}
