import 'package:flutter/material.dart';

import '../../core/presentation/widgets/empty_view.dart';
import 'paged_list_notifier.dart';

/// Lista con pie de paginación: botón "Cargar más", spinner o error con
/// reintento. [items] puede ser un subconjunto filtrado de `data.items`.
class PagedListBody<T> extends StatelessWidget {
  final PagedList<T> data;
  final List<T> items;
  final String emptyMessage;
  final Widget Function(T) itemBuilder;
  final VoidCallback onLoadMore;

  const PagedListBody({
    super.key,
    required this.data,
    required this.items,
    required this.emptyMessage,
    required this.itemBuilder,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !data.hasMore) return EmptyView(emptyMessage);

    final footer = _footer();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(emptyMessage)),
          ),
        for (final item in items) itemBuilder(item),
        ?footer,
      ],
    );
  }

  Widget? _footer() {
    if (data.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!data.hasMore) return null;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (data.loadMoreError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('No se pudo cargar más: ${data.loadMoreError}',
                  textAlign: TextAlign.center),
            ),
          Center(
            child: OutlinedButton(
              onPressed: onLoadMore,
              child: Text(data.loadMoreError != null ? 'Reintentar' : 'Cargar más'),
            ),
          ),
        ],
      ),
    );
  }
}
