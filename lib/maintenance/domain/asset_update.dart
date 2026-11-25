import 'criticality.dart';

/// Datos editables de un activo (PUT /assets/{id}). El código no cambia.
///
/// El PUT reemplaza la ficha, por eso siempre se envían también los campos
/// que el formulario no edita (plantId).
class AssetUpdate {
  final String name;
  final String location;
  final String assetType;
  final Criticality criticality;
  final String plantId;
  final String? productionLine;
  final double? latitude;
  final double? longitude;

  const AssetUpdate({
    required this.name,
    required this.location,
    required this.assetType,
    required this.criticality,
    required this.plantId,
    this.productionLine,
    this.latitude,
    this.longitude,
  });
}
