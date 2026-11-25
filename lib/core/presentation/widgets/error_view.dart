import 'package:flutter/material.dart';

/// Mensaje de error con botón "Reintentar".
///
/// [inline] = true para usarlo dentro de una lista/sección; false ocupa y
/// centra el área disponible (pantallas de listado).
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool inline;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisSize: inline ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        SizedBox(height: inline ? 12 : 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
    if (inline) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: column);
    }
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: column));
  }
}
