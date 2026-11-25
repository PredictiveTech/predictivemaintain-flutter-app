import 'package:flutter/material.dart';

import '../../core/error/failure.dart';
import '../../core/presentation/format.dart';

/// Muestra el error de una acción. Un 409 explica que el recurso cambió y
/// ofrece recargar con [onReload].
void showActionFailure(
  BuildContext context,
  Object error, {
  required String conflictMessage,
  required VoidCallback onReload,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  if (error is ConflictFailure) {
    messenger.showSnackBar(SnackBar(
      content: Text(conflictMessage),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(label: 'Recargar', onPressed: onReload),
    ));
  } else {
    messenger.showSnackBar(SnackBar(content: Text(describeActionFailure(error))));
  }
}
