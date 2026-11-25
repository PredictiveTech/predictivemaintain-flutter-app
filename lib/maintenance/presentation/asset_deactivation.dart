import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/deactivate_asset_use_case.dart';
import '../domain/asset_detail.dart';
import 'asset_actions.dart';
import 'dialogs.dart';

/// Flujo de baja (US-13): confirmar → intentar → si hay órdenes abiertas el
/// backend avisa (409) y se pide una segunda confirmación nombrando cuántas;
/// solo si el usuario acepta se repite con force=true.
Future<void> confirmAndDeactivate(
    BuildContext context, WidgetRef ref, AssetDetail asset) async {
  final actions = ref.read(assetActionsProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);

  final ok = await askConfirmation(
    context,
    title: 'Dar de baja el activo',
    message: '${asset.name} dejará de monitorearse y liberará su cupo del plan.',
    confirmLabel: 'Dar de baja',
  );
  if (!ok || !context.mounted) return;

  var result = await actions.deactivate(asset.id);
  if (result is AssetNeedsConfirmation) {
    if (!context.mounted) return;
    final n = result.openWorkOrders;
    final force = await askConfirmation(
      context,
      title: 'Órdenes de trabajo abiertas',
      message: n > 0
          ? 'El activo tiene $n ${n == 1 ? 'orden de trabajo abierta' : 'órdenes de trabajo abiertas'}. '
              '¿Dar de baja de todos modos?'
          : 'El activo tiene órdenes de trabajo abiertas. ¿Dar de baja de todos modos?',
      confirmLabel: 'Dar de baja de todos modos',
    );
    if (!force || !context.mounted) return;
    result = await actions.deactivate(asset.id, force: true);
  }

  if (result is AssetDeactivated) {
    messenger.showSnackBar(SnackBar(content: Text('${asset.name} fue dado de baja')));
    if (context.mounted) context.pop();
  }
}
