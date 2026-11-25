import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/paged_result.dart';

/// Elementos acumulados de las páginas cargadas hasta ahora.
class PagedList<T> {
  final List<T> items;
  final int nextPage;
  final int totalPages;
  final bool loadingMore;

  /// Falló la última carga de "más"; la lista ya cargada se conserva.
  final Object? loadMoreError;

  const PagedList({
    required this.items,
    required this.nextPage,
    required this.totalPages,
    this.loadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => nextPage < totalPages;

  PagedList<T> copyWith({
    List<T>? items,
    int? nextPage,
    int? totalPages,
    bool? loadingMore,
    Object? loadMoreError,
    bool clearError = false,
  }) =>
      PagedList(
        items: items ?? this.items,
        nextPage: nextPage ?? this.nextPage,
        totalPages: totalPages ?? this.totalPages,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
      );
}

/// Base de los listados paginados: `build` carga la página 0 y [loadMore] anexa
/// la siguiente. Al cambiar un filtro (que `fetch` lee con `ref.watch`) el
/// notifier se reconstruye y vuelve a la página 0.
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedList<T>> {
  Future<PagedResult<T>> fetch(int page);

  @override
  Future<PagedList<T>> build() async {
    final first = await fetch(0);
    return PagedList(items: first.items, nextPage: 1, totalPages: first.totalPages);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, clearError: true));
    try {
      final next = await fetch(current.nextPage);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        nextPage: current.nextPage + 1,
        totalPages: next.totalPages,
        loadingMore: false,
        clearError: true,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: e));
    }
  }
}
