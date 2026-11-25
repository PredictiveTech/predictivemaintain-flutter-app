import '../../maintenance/infrastructure/enum_parser.dart';
import '../domain/subscription.dart';

class SubscriptionPlanDto {
  final String id;
  final String name;
  final int assetLimit;
  final double amount;
  final String currency;

  const SubscriptionPlanDto({
    required this.id,
    required this.name,
    required this.assetLimit,
    required this.amount,
    required this.currency,
  });

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) => SubscriptionPlanDto(
        id: json['id'].toString(),
        name: json['name'] as String,
        assetLimit: (json['assetLimit'] as num).toInt(),
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
      );

  SubscriptionPlan toDomain() => SubscriptionPlan(
      id: id, name: name, assetLimit: assetLimit, amount: amount, currency: currency);
}

class SubscriptionDto {
  final Map<String, dynamic> json;

  const SubscriptionDto(this.json);

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) => SubscriptionDto(json);

  Subscription toDomain() {
    final cap = json['capacity'] as Map<String, dynamic>;
    final exp = json['expiry'] as Map<String, dynamic>;
    return Subscription(
      id: json['id'].toString(),
      status: parseEnum(SubscriptionStatus.values, json['status']),
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      monitoringAllowed: json['monitoringAllowed'] as bool,
      plan: SubscriptionPlanDto.fromJson(json['plan'] as Map<String, dynamic>).toDomain(),
      capacity: Capacity(
        limit: (cap['limit'] as num).toInt(),
        used: (cap['used'] as num).toInt(),
        available: (cap['available'] as num).toInt(),
        usagePercent: (cap['usagePercent'] as num).toDouble(),
        nearLimit: cap['nearLimit'] as bool,
      ),
      expiry: Expiry(
        daysRemaining: (exp['daysRemaining'] as num).toInt(),
        expiresSoon: exp['expiresSoon'] as bool,
        expired: exp['expired'] as bool,
      ),
    );
  }
}
