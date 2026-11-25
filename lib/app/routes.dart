/// Rutas con nombre de la app (la tabla vive en router.dart).
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static String assetDetail(String id) => '/assets/$id';
  static String alertDetail(String id) => '/alerts/$id';
  static String workOrderDetail(String id) => '/work-orders/$id';
}
