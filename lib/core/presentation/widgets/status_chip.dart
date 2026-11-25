import 'package:flutter/material.dart';

/// Pastilla de color con texto (y punto opcional). Base de los chips de
/// estado, severidad y rango.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final bool dot;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Icon(Icons.circle, color: color, size: 8),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
