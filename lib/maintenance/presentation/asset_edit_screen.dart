import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/widgets/error_view.dart';
import '../domain/asset_detail.dart';
import '../domain/asset_update.dart';
import '../domain/criticality.dart';
import 'asset_actions.dart';
import 'failure_feedback.dart';
import 'maintenance_providers.dart';

String _criticalityLabel(Criticality c) => switch (c) {
      Criticality.low => 'Baja',
      Criticality.medium => 'Media',
      Criticality.high => 'Alta',
      Criticality.critical => 'Crítica',
    };

/// Formulario de edición de la ficha (US-12). El código es de solo lectura.
class AssetEditScreen extends ConsumerWidget {
  final String assetId;

  const AssetEditScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(assetDetailProvider(assetId));
    return Scaffold(
      appBar: AppBar(title: const Text('Editar activo')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'No se pudo cargar el activo: $e',
          onRetry: () => ref.invalidate(assetDetailProvider(assetId)),
        ),
        data: (asset) => _EditForm(asset: asset),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final AssetDetail asset;

  const _EditForm({required this.asset});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.asset.name);
  late final _location = TextEditingController(text: widget.asset.location);
  late final _type = TextEditingController(text: widget.asset.assetType);
  late final _line = TextEditingController(text: widget.asset.productionLine ?? '');
  late final _lat = TextEditingController(text: widget.asset.latitude?.toString() ?? '');
  late final _lon = TextEditingController(text: widget.asset.longitude?.toString() ?? '');
  late Criticality _criticality = widget.asset.criticality;

  @override
  void dispose() {
    for (final c in [_name, _location, _type, _line, _lat, _lon]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, int max) {
    if (v == null || v.trim().isEmpty) return 'Obligatorio';
    if (v.length > max) return 'Máximo $max caracteres';
    return null;
  }

  String? _coordinate(String? v, double limit) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return 'Número inválido';
    if (n < -limit || n > limit) return 'Entre -${limit.toInt()} y ${limit.toInt()}';
    return null;
  }

  double? _parse(String v) =>
      v.trim().isEmpty ? null : double.parse(v.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final line = _line.text.trim();
    final ok = await ref.read(assetActionsProvider.notifier).save(
          widget.asset.id,
          AssetUpdate(
            name: _name.text.trim(),
            location: _location.text.trim(),
            assetType: _type.text.trim(),
            criticality: _criticality,
            plantId: widget.asset.plantId,
            productionLine: line.isEmpty ? null : line,
            latitude: _parse(_lat.text),
            longitude: _parse(_lon.text),
          ),
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Activo actualizado')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(assetActionsProvider, (_, state) {
      if (state.hasError) {
        showActionFailure(context, state.error!,
            conflictMessage: 'El activo no se puede editar (¿está dado de baja?).',
            onReload: () => ref.invalidate(assetDetailProvider(widget.asset.id)));
      }
    });
    final saving = ref.watch(assetActionsProvider).isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: widget.asset.code,
            enabled: false,
            decoration: const InputDecoration(labelText: 'Código (no editable)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => _required(v, 120),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Ubicación'),
            validator: (v) => _required(v, 120),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _type,
            decoration: const InputDecoration(labelText: 'Tipo de activo'),
            validator: (v) => _required(v, 80),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Criticality>(
            initialValue: _criticality,
            decoration: const InputDecoration(labelText: 'Criticidad'),
            items: [
              for (final c in Criticality.values)
                DropdownMenuItem(value: c, child: Text(_criticalityLabel(c))),
            ],
            onChanged: (c) => setState(() => _criticality = c ?? _criticality),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _line,
            decoration: const InputDecoration(labelText: 'Línea de producción (opcional)'),
            validator: (v) => (v?.length ?? 0) > 100 ? 'Máximo 100 caracteres' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lat,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: const InputDecoration(labelText: 'Latitud (opcional)'),
            validator: (v) => _coordinate(v, 90),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lon,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: const InputDecoration(labelText: 'Longitud (opcional)'),
            validator: (v) => _coordinate(v, 180),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
