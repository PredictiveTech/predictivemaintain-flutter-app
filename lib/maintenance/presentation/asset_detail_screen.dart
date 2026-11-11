import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../domain/asset.dart';
import '../domain/asset_status.dart';
import '../domain/sensor_reading.dart';
import '../infrastructure/asset_dto.dart';
import '../infrastructure/sensor_reading_dto.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final _client = HttpClient(tokenProvider: () async => auth.accessToken);
  bool _loading = true;
  String? _error;
  Asset? _asset;
  List<SensorReading> _sensors = const [];

  @override
  void initState() {
    super.initState();
    _loadAssetDetail();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadAssetDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assetUri = Uri.parse('$baseUrl/api/v1/assets/${widget.assetId}');
      final sensorsUri = Uri.parse('$baseUrl/api/v1/assets/${widget.assetId}/sensors');

      final assetResponse = await _client.get(assetUri);
      if (assetResponse.statusCode < 200 || assetResponse.statusCode >= 300) {
        throw Exception('Error al cargar activo (HTTP ${assetResponse.statusCode})');
      }

      final sensorsResponse = await _client.get(sensorsUri);
      if (sensorsResponse.statusCode < 200 || sensorsResponse.statusCode >= 300) {
        throw Exception('Error al cargar sensores (HTTP ${sensorsResponse.statusCode})');
      }

      final assetDto = AssetDto.fromJson(
        jsonDecode(assetResponse.body) as Map<String, dynamic>,
      );
      final assetObj = assetDto.toDomain();

      final sensorsList = (jsonDecode(sensorsResponse.body) as List)
          .map((e) => SensorReadingDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();

      if (!mounted) return;
      setState(() {
        _asset = assetObj;
        _sensors = sensorsList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el detalle del activo: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static Color _statusColor(AssetStatus status) => switch (status) {
        AssetStatus.operational => Colors.green.shade700,
        AssetStatus.inAlert => Colors.red.shade700,
        AssetStatus.noCommunication => Colors.grey.shade700,
      };

  static Color _statusBgColor(AssetStatus status) => switch (status) {
        AssetStatus.operational => Colors.green.shade50,
        AssetStatus.inAlert => Colors.red.shade50,
        AssetStatus.noCommunication => Colors.grey.shade200,
      };

  static String _statusLabel(AssetStatus status) => switch (status) {
        AssetStatus.operational => 'Operativo',
        AssetStatus.inAlert => 'Alerta',
        AssetStatus.noCommunication => 'Sin comunicación',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_asset?.name ?? 'Detalle de Activo'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadAssetDetail,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final asset = _asset;
    if (asset == null) {
      return const Center(child: Text('Activo no encontrado'));
    }

    final color = _statusColor(asset.status);
    final bgColor = _statusBgColor(asset.status);

    return RefreshIndicator(
      onRefresh: _loadAssetDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: color, size: 8),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel(asset.status),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Código: ${asset.code}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        asset.location,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tipo: ${asset.assetType} | Criticidad: ${asset.criticality.name.toUpperCase()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sensores en Tiempo Real',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_sensors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No hay sensores registrados para este activo')),
            )
          else
            ..._sensors.map((sensor) => _SensorCard(sensor: sensor)),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final SensorReading sensor;

  const _SensorCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final isNormal = sensor.rangeStatus.toUpperCase() == 'NORMAL' ||
        sensor.rangeStatus.toUpperCase() == 'IN_RANGE' ||
        sensor.rangeStatus.toUpperCase() == 'OK';
    final statusColor = isNormal ? Colors.green.shade700 : Colors.red.shade700;
    final statusBg = isNormal ? Colors.green.shade50 : Colors.red.shade50;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.metric,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lectura: ${sensor.latestReading} ${sensor.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (sensor.threshold != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Umbral: ${sensor.threshold}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sensor.rangeStatus,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
