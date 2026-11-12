import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../domain/asset.dart';
import '../infrastructure/asset_dto.dart';
import '../infrastructure/paged_response_dto.dart';
import 'asset_detail_screen.dart';
import 'asset_status_style.dart';

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

  static IconData _assetIcon(String type) => switch (type.toUpperCase()) {
        'PUMP' => Icons.water_drop,
        'MOTOR' => Icons.electric_bolt,
        'COMPRESSOR' => Icons.air,
        'CONVEYOR' => Icons.conveyor_belt,
        'EXTRUDER' => Icons.settings,
        _ => Icons.factory,
      };

  @override
  Widget build(BuildContext context) {
    final color = assetStatusColor(asset.status);
    final bgColor = assetStatusBgColor(asset.status);
    final iconData = _assetIcon(asset.assetType);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(assetId: asset.id, status: asset.status),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                                assetStatusLabel(asset.status),
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
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${asset.code}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            asset.location,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
