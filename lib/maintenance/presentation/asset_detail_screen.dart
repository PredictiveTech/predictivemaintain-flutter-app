import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../domain/asset_detail.dart';
import '../domain/asset_status.dart';
import '../domain/sensor_reading.dart';
import '../infrastructure/asset_detail_dto.dart';
import '../infrastructure/sensor_reading_dto.dart';
import 'asset_status_style.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  /// Estado calculado que ya trae el listado (el endpoint de detalle no lo
  /// incluye). Si es null no se muestra el chip de estado.
  final AssetStatus? status;

  const AssetDetailScreen({super.key, required this.assetId, this.status});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _HttpFailure implements Exception {
  final int statusCode;
  const _HttpFailure(this.statusCode);
}

/// Mensaje legible para un error de carga, diferenciando los HTTP comunes.
String _describeError(Object e, String what) {
  if (e is _HttpFailure) {
    return switch (e.statusCode) {
      401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
      403 => 'No tienes permisos para ver $what.',
      404 => 'No se encontró $what.',
      >= 500 => 'El servidor tuvo un problema al cargar $what (HTTP ${e.statusCode}).',
      _ => 'No se pudo cargar $what (HTTP ${e.statusCode}).',
    };
  }
  if (e is FormatException || e is TypeError) {
    return 'La respuesta del servidor para $what no tiene el formato esperado.';
  }
  return 'No se pudo cargar $what. Revisa tu conexión.';
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final _client = HttpClient(tokenProvider: () async => auth.accessToken);
  bool _loading = true;
  AssetDetail? _asset;
  String? _assetError;
  List<SensorReading> _sensors = const [];
  String? _sensorsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<T> _get<T>(String path, T Function(dynamic json) parse) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _HttpFailure(response.statusCode);
    }
    return parse(jsonDecode(response.body));
  }

  /// Carga detalle y sensores en paralelo; cada uno falla de forma independiente.
  Future<void> _load() async {
    setState(() => _loading = true);
    final id = widget.assetId;

    Future<void> loadAsset() async {
      try {
        final asset = await _get(
          '/api/v1/assets/$id',
          (j) => AssetDetailDto.fromJson(j as Map<String, dynamic>).toDomain(),
        );
        _asset = asset;
        _assetError = null;
      } catch (e) {
        _assetError = _describeError(e, 'el activo');
      }
    }

    Future<void> loadSensors() async {
      try {
        final sensors = await _get(
          '/api/v1/assets/$id/sensors',
          (j) => (j as List)
              .map((e) => SensorReadingDto.fromJson(e as Map<String, dynamic>).toDomain())
              .toList(),
        );
        _sensors = sensors;
        _sensorsError = null;
      } catch (e) {
        _sensorsError = _describeError(e, 'los sensores');
      }
    }

    await Future.wait([loadAsset(), loadSensors()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_asset?.name ?? 'Detalle de Activo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  const Text(
                    'Sensores en Tiempo Real',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._buildSensors(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final asset = _asset;
    if (asset == null) {
      return _ErrorBox(message: _assetError ?? 'Activo no encontrado', onRetry: _load);
    }
    final status = widget.status;
    return Card(
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (status != null)
                  _Chip(
                    label: assetStatusLabel(status),
                    color: assetStatusColor(status),
                    background: assetStatusBgColor(status),
                    dot: true,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Código: ${asset.code}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(asset.location,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo: ${asset.assetType} | Criticidad: ${asset.criticality.name.toUpperCase()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (asset.productionLine != null)
              Text('Línea: ${asset.productionLine}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (!asset.active)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: _Chip(
                  label: 'Inactivo',
                  color: Colors.grey,
                  background: Color(0xFFEEEEEE),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSensors() {
    final error = _sensorsError;
    if (error != null) return [_ErrorBox(message: error, onRetry: _load)];
    if (_sensors.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No hay sensores registrados para este activo')),
        ),
      ];
    }
    return [for (final s in _sensors) _SensorCard(sensor: s)];
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final bool dot;

  const _Chip({
    required this.label,
    required this.color,
    required this.background,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Icon(Icons.circle, color: color, size: 8),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

String _formatNumber(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _formatAgo(DateTime t) {
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'hace unos segundos';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}

class _SensorCard extends StatelessWidget {
  final SensorReading sensor;

  const _SensorCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final noComm = sensor.communication == CommunicationStatus.noCommunication;
    final reading = sensor.latestReading;
    final threshold = sensor.threshold;
    final lastReceived = sensor.lastReceivedAt;

    final (rangeLabel, rangeColor, rangeBg) = switch (sensor.rangeStatus) {
      RangeStatus.normal => ('Normal', Colors.green.shade700, Colors.green.shade50),
      RangeStatus.outOfRange => ('Fuera de rango', Colors.red.shade700, Colors.red.shade50),
      RangeStatus.unknown => ('Sin datos', Colors.grey.shade700, Colors.grey.shade200),
    };

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(sensor.metric,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                _Chip(label: rangeLabel, color: rangeColor, background: rangeBg),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reading == null
                  ? 'Sin lecturas'
                  : 'Lectura: ${_formatNumber(reading.value)} ${sensor.unit}',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
            ),
            if (threshold != null)
              Text(
                'Umbral: ${_formatNumber(threshold.lowerBound)} – '
                '${_formatNumber(threshold.upperBound)} ${sensor.unit}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            else
              Text('Umbral no configurado',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  noComm ? Icons.signal_wifi_off : Icons.wifi,
                  size: 14,
                  color: noComm ? Colors.orange.shade800 : Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    noComm
                        ? (lastReceived == null
                            ? 'Sin comunicación · nunca reportó'
                            : 'Sin comunicación · última lectura ${_formatAgo(lastReceived)}')
                        : (lastReceived == null
                            ? 'En línea'
                            : 'En línea · última lectura ${_formatAgo(lastReceived)}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: noComm ? FontWeight.w600 : FontWeight.normal,
                      color: noComm ? Colors.orange.shade800 : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (!sensor.active)
                  Text('Inactivo',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
