import 'package:flutter_test/flutter_test.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/sensor_reading.dart';
import 'package:predictivemaintain_flutter_app/maintenance/domain/severity.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/asset_detail_dto.dart';
import 'package:predictivemaintain_flutter_app/maintenance/infrastructure/sensor_reading_dto.dart';

void main() {
  test('parsea el panel de sensores con objetos anidados y nulls', () {
    final json = <Map<String, dynamic>>[
      {
        'id': '6f3d7a7a-d158-4907-8cbe-863f0ea98ac3',
        'metric': 'TEMPERATURE',
        'unit': '°C',
        'active': true,
        'communication': 'ONLINE',
        'lastReceivedAt': '2026-10-10T03:44:41Z',
        'latestReading': {'value': 101.25, 'measuredAt': '2026-10-10T03:44:41Z'},
        'threshold': {
          'lowerBound': 20.0,
          'upperBound': 85,
          'severity': 'CRITICAL',
          'version': 2,
        },
        'rangeStatus': 'OUT_OF_RANGE',
      },
      {
        'id': 'a1',
        'metric': 'VIBRATION',
        'unit': 'mm/s',
        'active': true,
        'communication': 'NO_COMMUNICATION',
        'lastReceivedAt': null,
        'latestReading': null,
        'threshold': null,
        'rangeStatus': 'UNKNOWN',
      },
    ];
    final sensors =
        json.map((e) => SensorReadingDto.fromJson(e).toDomain()).toList();

    final first = sensors[0];
    expect(first.communication, CommunicationStatus.online);
    expect(first.rangeStatus, RangeStatus.outOfRange);
    expect(first.latestReading!.value, 101.25);
    expect(first.latestReading!.measuredAt, DateTime.utc(2026, 10, 10, 3, 44, 41));
    expect(first.threshold!.upperBound, 85.0);
    expect(first.threshold!.severity, Severity.critical);
    expect(first.threshold!.version, 2);

    final second = sensors[1];
    expect(second.communication, CommunicationStatus.noCommunication);
    expect(second.rangeStatus, RangeStatus.unknown);
    expect(second.lastReceivedAt, isNull);
    expect(second.latestReading, isNull);
    expect(second.threshold, isNull);
  });

  test('parsea AssetResource sin status ni sensorTypes y con nulls', () {
    final asset = AssetDetailDto.fromJson({
      'id': 'c7c0d541-bc51-4f78-a0a3-459669a8f738',
      'code': 'COMP-003',
      'name': 'Compresor de aire 3',
      'location': 'Planta 1',
      'plantId': 'p1',
      'productionLine': null,
      'assetType': 'COMPRESSOR',
      'criticality': 'HIGH',
      'latitude': null,
      'longitude': null,
      'active': true,
    }).toDomain();

    expect(asset.code, 'COMP-003');
    expect(asset.productionLine, isNull);
    expect(asset.latitude, isNull);
  });
}
