import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../domain/alert.dart';
import '../domain/alert_status.dart';
import '../domain/severity.dart';
import '../infrastructure/alert_dto.dart';
import '../infrastructure/paged_response_dto.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _client = HttpClient(tokenProvider: () async => auth.accessToken);
  bool _loading = true;
  String? _error;
  List<Alert> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _client.get(Uri.parse('$baseUrl/api/v1/alerts'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final page = PagedResponseDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        AlertDto.fromJson,
      ).toDomain((dto) => dto.toDomain());
      if (!mounted) return;
      setState(() => _alerts = page.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar las alertas: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _loadAlerts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_alerts.isEmpty) {
      return const Center(child: Text('No hay alertas'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _alerts.length,
      itemBuilder: (context, index) => _AlertCard(alert: _alerts[index]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  static Color _severityColor(Severity severity) => switch (severity) {
        Severity.critical => Colors.red,
        Severity.warning => Colors.amber.shade800,
        Severity.high => Colors.orange,
        Severity.medium => Colors.yellow.shade800,
        Severity.low => Colors.blue,
      };

  static String _severityLabel(Severity severity) => switch (severity) {
        Severity.critical => 'Crítica',
        Severity.warning => 'Advertencia',
        Severity.high => 'Alta',
        Severity.medium => 'Media',
        Severity.low => 'Baja',
      };

  static String _statusLabel(AlertStatus status) => switch (status) {
        AlertStatus.inReview => 'En revisión',
        AlertStatus.confirmed => 'Confirmada',
        AlertStatus.discarded => 'Descartada',
        AlertStatus.resolved => 'Resuelta',
      };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    return Card(
      child: ListTile(
        title: Text(alert.assetName),
        subtitle: Text('Estado: ${_statusLabel(alert.status)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              _severityLabel(alert.severity),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
