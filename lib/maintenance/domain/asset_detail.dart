import 'criticality.dart';

/// Activo devuelto por GET /api/v1/assets/{assetId}.
///
/// A diferencia de [Asset] (listado), no incluye `status` ni `sensorTypes`.
class AssetDetail {
  final String id;
  final String code;
  final String name;
  final String location;
  final String plantId;
  final String? productionLine;
  final String assetType;
  final Criticality criticality;
  final double? latitude;
  final double? longitude;
  final bool active;

  const AssetDetail({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
    required this.plantId,
    this.productionLine,
    required this.assetType,
    required this.criticality,
    this.latitude,
    this.longitude,
    required this.active,
  });
}
