import '../domain/asset_detail.dart';
import '../domain/criticality.dart';
import 'enum_parser.dart';

/// Respuesta de GET /api/v1/assets/{assetId} (AssetResource del backend).
class AssetDetailDto {
  final String id;
  final String code;
  final String name;
  final String location;
  final String plantId;
  final String? productionLine;
  final String assetType;
  final String criticality;
  final double? latitude;
  final double? longitude;
  final bool active;

  const AssetDetailDto({
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

  factory AssetDetailDto.fromJson(Map<String, dynamic> json) => AssetDetailDto(
        id: json['id'].toString(),
        code: json['code'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        plantId: json['plantId'].toString(),
        productionLine: json['productionLine'] as String?,
        assetType: json['assetType'] as String,
        criticality: json['criticality'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        active: json['active'] as bool,
      );

  AssetDetail toDomain() => AssetDetail(
        id: id,
        code: code,
        name: name,
        location: location,
        plantId: plantId,
        productionLine: productionLine,
        assetType: assetType,
        criticality: parseEnum(Criticality.values, criticality),
        latitude: latitude,
        longitude: longitude,
        active: active,
      );
}
