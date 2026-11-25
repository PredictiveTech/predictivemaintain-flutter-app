/// Rutas con nombre de la app (la tabla vive en router.dart).
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static String assetDetail(String id) => '/assets/$id';
  static String alertDetail(String id) => '/alerts/$id';
  static String workOrderDetail(String id) => '/work-orders/$id';
  static String assetEdit(String id) => '/assets/$id/edit';
  static String assetAvailability(String id) => '/assets/$id/availability';
  static const comparison = '/reports/comparison';
  static const plans = '/subscription/plans';
}
