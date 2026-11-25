import '../../core/network/api_client.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';
import 'subscription_dto.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _api;

  SubscriptionRepositoryImpl(this._api);

  Subscription _sub(dynamic json) => parseResponse(
        () => SubscriptionDto.fromJson(json as Map<String, dynamic>).toDomain(),
      );

  @override
  Future<Subscription> getSubscription() async => _sub(await _api.get('/subscription'));

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final json = await _api.get('/plans');
    return parseResponse(
      () => (json as List)
          .map((e) => SubscriptionPlanDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList(),
    );
  }

  @override
  Future<Subscription> changePlan(String planId) async =>
      _sub(await _api.put('/subscription/plan', body: {'planId': planId}));
}
