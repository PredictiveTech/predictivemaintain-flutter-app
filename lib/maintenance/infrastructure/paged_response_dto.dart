import '../domain/paged_result.dart';

/// Respuesta paginada: `{ items: [...], totalElements, page, size, totalPages }`.
class PagedResponseDto<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const PagedResponseDto({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) =>
      PagedResponseDto(
        items: (json['items'] as List)
            .map((e) => parseItem(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num).toInt(),
        size: (json['size'] as num).toInt(),
        totalElements: (json['totalElements'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
      );

  /// Convierte a dominio aplicando [mapItem] a cada elemento.
  PagedResult<R> toDomain<R>(R Function(T) mapItem) => PagedResult(
        items: items.map(mapItem).toList(),
        number: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
      );
}
