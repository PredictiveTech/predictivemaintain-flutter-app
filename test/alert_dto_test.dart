import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/alert_status.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/severity.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/alert_dto.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/paged_response_dto.dart';

void main() {
  test('parsea una respuesta real de /alerts', () {
    final page = PagedResponseDto.fromJson({
      'items': [
        {
          'id': '6f3d7a7a-d158-4907-8cbe-863f0ea98ac3',
          'assetId': 'c7c0d541-bc51-4f78-a0a3-459669a8f738',
          'assetCode': 'COMP-003',
          'assetName': 'Compresor de aire 3',
          'severity': 'WARNING',
          'status': 'IN_REVIEW',
          'raisedAt': '2026-10-10T03:44:43.233041Z',
          'discardReason': null,
          'version': 0,
          'diagnostic': {
            'metric': 'TEMPERATURE',
            'unit': '°C',
            'observedValue': 101.25,
            'lowerBound': 20.0,
            'upperBound': 85.0,
            'measuredAt': '2026-10-10T03:44:41Z',
          },
        },
        {
          'id': 'x',
          'assetId': 'y',
          'assetCode': 'FAJA-021',
          'assetName': 'Faja empacadora',
          'severity': 'CRITICAL',
          'status': 'DISCARDED',
          'raisedAt': '2026-10-08T19:12:31.128748Z',
          'discardReason': 'Prueba',
          'version': 1,
          'diagnostic': null,
        },
      ],
      'totalElements': 2,
      'page': 0,
      'size': 20,
      'totalPages': 1,
    }, AlertDto.fromJson).toDomain((d) => d.toDomain());

    final first = page.items[0];
    expect(first.severity, Severity.warning);
    expect(first.status, AlertStatus.inReview);
    expect(first.diagnostic!.metric, 'TEMPERATURE');
    expect(first.diagnostic!.observedValue, 101.25);
    expect(page.items[1].status, AlertStatus.discarded);
    expect(page.items[1].diagnostic, isNull);
  });
}
