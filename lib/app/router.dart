import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../iam/presentation/login_screen.dart';
import '../maintenance/domain/asset_status.dart';
import '../maintenance/presentation/alert_detail_screen.dart';
import '../maintenance/presentation/asset_detail_screen.dart';
import '../maintenance/presentation/asset_edit_screen.dart';
import '../maintenance/presentation/availability_screen.dart';
import '../maintenance/presentation/comparison_screen.dart';
import '../maintenance/presentation/work_order_detail_screen.dart';
import '../navigation/home_screen.dart';
import '../subscription/presentation/plans_screen.dart';
import 'routes.dart';
import 'session_controller.dart';

/// Tabla única de rutas. Con sesión se accede a home y detalle; sin sesión,
/// cualquier ruta redirige a login (y viceversa).
final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ValueNotifier<bool>(ref.read(sessionControllerProvider) != null);
  ref.listen(sessionControllerProvider, (_, session) => loggedIn.value = session != null);
  ref.onDispose(loggedIn.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: loggedIn,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == AppRoutes.login;
      if (!loggedIn.value) return atLogin ? null : AppRoutes.login;
      return atLogin ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'assets/:id',
            builder: (context, state) => AssetDetailScreen(
              assetId: state.pathParameters['id']!,
              // El estado calculado solo viene en el listado; se pasa como extra.
              status: state.extra as AssetStatus?,
            ),
          ),
          GoRoute(
            path: 'assets/:id/edit',
            builder: (context, state) =>
                AssetEditScreen(assetId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'assets/:id/availability',
            builder: (context, state) =>
                AvailabilityScreen(assetId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'reports/comparison',
            builder: (context, state) => const ComparisonScreen(),
          ),
          GoRoute(
            path: 'subscription/plans',
            builder: (context, state) => const PlansScreen(),
          ),
          GoRoute(
            path: 'alerts/:id',
            builder: (context, state) =>
                AlertDetailScreen(alertId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'work-orders/:id',
            builder: (context, state) =>
                WorkOrderDetailScreen(workOrderId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
