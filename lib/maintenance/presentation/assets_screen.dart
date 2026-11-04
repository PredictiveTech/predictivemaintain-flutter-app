import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../domain/asset.dart';
import '../domain/asset_status.dart';
import '../infrastructure/asset_dto.dart';
import '../infrastructure/paged_response_dto.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _client = HttpClient(tokenProvider: () async => auth.accessToken);
  bool _loading = true;
  String? _error;
  List<Asset> _assets = const [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _client.get(Uri.parse('$baseUrl/api/v1/assets'));
      // TODO(debug): quitar este print temporal.
      // ignore: avoid_print
      print('GET /assets -> ${response.statusCode}: ${response.body}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final page = PagedResponseDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        AssetDto.fromJson,
      ).toDomain((dto) => dto.toDomain());
      if (!mounted) return;
      setState(() => _assets = page.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar los activos: $e');
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
                onPressed: _loadAssets,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_assets.isEmpty) {
      return const Center(child: Text('No hay activos'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _assets.length,
      itemBuilder: (context, index) => _AssetCard(asset: _assets[index]),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;

  const _AssetCard({required this.asset});

  static Color _statusColor(AssetStatus status) => switch (status) {
        AssetStatus.operational => Colors.green,
        AssetStatus.inAlert => Colors.red,
        AssetStatus.noCommunication => Colors.grey,
      };

  static String _statusLabel(AssetStatus status) => switch (status) {
        AssetStatus.operational => 'Operativo',
        AssetStatus.inAlert => 'Alerta',
        AssetStatus.noCommunication => 'Sin comunicación',
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(asset.status);
    return Card(
      child: ListTile(
        title: Text(asset.name),
        subtitle: Text(asset.code),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              _statusLabel(asset.status),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
