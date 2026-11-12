import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/asset_dto.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/paged_response_dto.dart';

void main() {
  test('parsea la paginación real del backend', () {
    final page = PagedResponseDto.fromJson({
      'items': [
        {
          'id': 1,
          'code': 'A-1',
          'name': 'Bomba',
          'location': 'Planta',
          'assetType': 'PUMP',
          'criticality': 'HIGH',
          'active': true,
          'status': 'NO_COMMUNICATION',
          'sensorTypes': ['TEMPERATURE'],
        },
      ],
      'totalElements': 5,
      'page': 0,
      'size': 20,
      'totalPages': 1,
    }, AssetDto.fromJson).toDomain((d) => d.toDomain());

    expect(page.items.single.name, 'Bomba');
    expect(page.number, 0);
    expect(page.size, 20);
    expect(page.totalElements, 5);
    expect(page.totalPages, 1);
  });
}
