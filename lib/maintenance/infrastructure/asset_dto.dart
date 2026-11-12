import '../domain/asset.dart';
import '../domain/asset_status.dart';
import '../domain/criticality.dart';
import 'enum_parser.dart';

class AssetDto {
  final String id;
  final String code;
  final String name;
  final String location;
  final String assetType;
  final String criticality;
  final bool active;
  final String status;
  final List<String> sensorTypes;

  const AssetDto({
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

  factory AssetDto.fromJson(Map<String, dynamic> json) => AssetDto(
        id: json['id'].toString(),
        code: json['code'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        assetType: json['assetType'] as String,
        criticality: json['criticality'] as String,
        active: json['active'] as bool,
        status: json['status'] as String,
        sensorTypes: List<String>.from(json['sensorTypes'] as List),
      );

  Asset toDomain() => Asset(
        id: id,
        code: code,
        name: name,
        location: location,
        assetType: assetType,
        criticality: parseEnum(Criticality.values, criticality),
        active: active,
        status: parseEnum(AssetStatus.values, status),
        sensorTypes: sensorTypes,
      );
}
