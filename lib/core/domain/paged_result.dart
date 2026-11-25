/// Resultado paginado genérico de los endpoints de listado.
class PagedResult<T> {
  final List<T> items;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });
}
