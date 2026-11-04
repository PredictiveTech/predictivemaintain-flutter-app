import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../domain/work_order.dart';
import '../domain/work_order_status.dart';
import '../infrastructure/paged_response_dto.dart';
import '../infrastructure/work_order_dto.dart';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  final _client = HttpClient(tokenProvider: () async => auth.accessToken);
  bool _loading = true;
  String? _error;
  List<WorkOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await _client.get(Uri.parse('$baseUrl/api/v1/work-orders'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final page = PagedResponseDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        WorkOrderDto.fromJson,
      ).toDomain((dto) => dto.toDomain());
      if (!mounted) return;
      setState(() => _orders = page.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar las órdenes de trabajo: $e');
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
                onPressed: _loadOrders,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('No hay órdenes de trabajo'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _WorkOrderCard(order: _orders[index]),
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder order;

  const _WorkOrderCard({required this.order});

  static Color _statusColor(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.pending => Colors.orange,
        WorkOrderStatus.inProgress => Colors.blue,
        WorkOrderStatus.completed => Colors.green,
      };

  static String _statusLabel(WorkOrderStatus status) => switch (status) {
        WorkOrderStatus.pending => 'Pendiente',
        WorkOrderStatus.inProgress => 'En progreso',
        WorkOrderStatus.completed => 'Completada',
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final technician = order.assignedUserId;
    return Card(
      child: ListTile(
        title: Text(order.assetName),
        subtitle: technician == null ? null : Text('Técnico: $technician'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              _statusLabel(order.status),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
