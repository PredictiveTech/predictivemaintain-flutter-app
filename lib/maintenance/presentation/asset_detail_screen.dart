import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../core/presentation/widgets/status_chip.dart';
import '../domain/asset_detail.dart';
import '../domain/asset_status.dart';
import '../domain/sensor_reading.dart';
import 'asset_status_style.dart';
import 'maintenance_providers.dart';

/// Mensaje legible para un error de carga, diferenciando los HTTP comunes.
String _describeError(Object e, String what) {
  if (e is Failure) {
    final code = e.statusCode;
    if (code != null) {
      return switch (code) {
        401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
        403 => 'No tienes permisos para ver $what.',
        404 => 'No se encontró $what.',
        >= 500 => 'El servidor tuvo un problema al cargar $what (HTTP $code).',
        _ => 'No se pudo cargar $what (HTTP $code).',
      };
    }
    if (e is MalformedResponseFailure) {
      return 'La respuesta del servidor para $what no tiene el formato esperado.';
    }
  }
  return 'No se pudo cargar $what. Revisa tu conexión.';
}

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  /// Estado calculado que ya trae el listado (el endpoint de detalle no lo
  /// incluye). Si es null no se muestra el chip de estado.
  final AssetStatus? status;

  const AssetDetailScreen({super.key, required this.assetId, this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(assetDetailProvider(assetId));
    final sensors = ref.watch(assetSensorsProvider(assetId));
    // Detalle y sensores se recargan juntos y fallan de forma independiente.
    void reload() {
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(assetSensorsProvider(assetId));
    }

    final loading = detail.isLoading || sensors.isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(detail.value?.name ?? 'Detalle de Activo')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(detail, reload),
                  const SizedBox(height: 20),
                  const Text(
                    'Sensores en Tiempo Real',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._buildSensors(sensors, reload),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(AsyncValue<AssetDetail> detail, VoidCallback onRetry) {
    final asset = detail.value;
    if (asset == null) {
      return ErrorView(
        message: detail.hasError
            ? _describeError(detail.error!, 'el activo')
            : 'Activo no encontrado',
        onRetry: onRetry,
        inline: true,
      );
    }
    final status = this.status;
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
                  StatusChip(
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
                child: StatusChip(
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

  List<Widget> _buildSensors(
      AsyncValue<List<SensorReading>> sensors, VoidCallback onRetry) {
    if (sensors.hasError) {
      return [
        ErrorView(
          message: _describeError(sensors.error!, 'los sensores'),
          onRetry: onRetry,
          inline: true,
        ),
      ];
    }
    final list = sensors.value ?? const <SensorReading>[];
    if (list.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No hay sensores registrados para este activo')),
        ),
      ];
    }
    return [for (final s in list) _SensorCard(sensor: s)];
  }
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
                StatusChip(label: rangeLabel, color: rangeColor, background: rangeBg),
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
