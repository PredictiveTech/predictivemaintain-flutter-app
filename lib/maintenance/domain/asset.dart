import 'asset_status.dart';
import 'criticality.dart';

/// Activo devuelto por GET /api/v1/assets.
class Asset {
  final String id;
  final String code;
  final String name;
  final String location;
  final String assetType;
  final Criticality criticality;
  final bool active;
  final AssetStatus status;
  final List<String> sensorTypes;

  const Asset({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
    required this.assetType,
    required this.criticality,
    required this.active,
    required this.status,
    required this.sensorTypes,
  });
}
