enum SubscriptionStatus { active, suspended, cancelled }

/// Plan comercial (GET /plans) o plan vigente dentro de la suscripción.
class SubscriptionPlan {
  final String id;
  final String name;
  final int assetLimit;
  final double amount;
  final String currency;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.assetLimit,
    required this.amount,
    required this.currency,
  });
}

class Capacity {
  final int limit;
  final int used;
  final int available;
  final double usagePercent;

  /// El backend lo activa desde el 90 % de uso.
  final bool nearLimit;

  const Capacity({
    required this.limit,
    required this.used,
    required this.available,
    required this.usagePercent,
    required this.nearLimit,
  });
}

class Expiry {
  final int daysRemaining;
  final bool expiresSoon;
  final bool expired;

  const Expiry({
    required this.daysRemaining,
    required this.expiresSoon,
    required this.expired,
  });
}

/// GET /api/v1/subscription.
class Subscription {
  final String id;
  final SubscriptionStatus status;
  final DateTime startsAt;

  /// Fecha de vencimiento / renovación.
  final DateTime endsAt;
  final bool monitoringAllowed;
  final SubscriptionPlan plan;
  final Capacity capacity;
  final Expiry expiry;

  const Subscription({
    required this.id,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.monitoringAllowed,
    required this.plan,
    required this.capacity,
    required this.expiry,
  });
}
