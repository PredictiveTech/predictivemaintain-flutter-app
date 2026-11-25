import 'package:flutter/material.dart';

import '../iam/domain/user_repository.dart';
import '../iam/presentation/profile_screen.dart';
import '../maintenance/presentation/alerts_screen.dart';
import '../maintenance/presentation/assets_screen.dart';
import '../maintenance/presentation/work_orders_screen.dart';
import '../subscription/presentation/subscription_screen.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final Widget Function() build;

  const NavDestination(this.label, this.icon, this.build);
}

const _assets = NavDestination('Activos', Icons.precision_manufacturing, AssetsScreen.new);
const _alerts = NavDestination('Alertas', Icons.notifications_active, AlertsScreen.new);
const _orders = NavDestination('Órdenes de trabajo', Icons.assignment, WorkOrdersScreen.new);
const _subscription = NavDestination('Suscripción', Icons.workspace_premium, SubscriptionScreen.new);
const _profile = NavDestination('Perfil', Icons.person, ProfileScreen.new);

/// Pestañas de la barra inferior según los roles de la sesión.
///
/// El gerente de mantenimiento ve las cinco (la suscripción es de gestión de
/// la empresa); el resto de roles no ve Suscripción.
List<NavDestination> destinationsFor(List<String> roles) =>
    roles.contains(UserRoles.manager)
        ? const [_assets, _alerts, _orders, _subscription, _profile]
        : const [_assets, _alerts, _orders, _profile];
