import 'package:flutter/material.dart';

/// Pide un texto obligatorio (motivo). Devuelve null si se cancela.
Future<String?> askRequiredText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  int maxLength = 500,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RequiredTextDialog(
        title: title, label: label, confirmLabel: confirmLabel, maxLength: maxLength),
  );
}

class _RequiredTextDialog extends StatefulWidget {
  final String title;
  final String label;
  final String confirmLabel;
  final int maxLength;

  const _RequiredTextDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.maxLength,
  });

  @override
  State<_RequiredTextDialog> createState() => _RequiredTextDialogState();
}

class _RequiredTextDialogState extends State<_RequiredTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: widget.maxLength,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
        FilledButton(
          // Deshabilitado mientras el texto esté vacío: el motivo es obligatorio.
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

Future<bool> askConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}
