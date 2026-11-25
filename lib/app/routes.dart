/// Rutas con nombre de la app (la tabla vive en router.dart).
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static String assetDetail(String id) => '/assets/$id';
}
