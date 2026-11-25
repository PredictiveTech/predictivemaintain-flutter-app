import 'package:flutter/material.dart';

/// Fila de chips de selección única con una opción "Todos" (valor null).
class FilterChipsRow<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T?> onSelected;

  const FilterChipsRow({
    super.key,
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text('$title:', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 8),
            for (final option in <T?>[null, ...options])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(option == null ? 'Todos' : labelOf(option)),
                  selected: selected == option,
                  onSelected: (_) => onSelected(option),
                ),
              ),
          ],
        ),
      );
}
