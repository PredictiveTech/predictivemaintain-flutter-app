import '../domain/paged_result.dart';

/// Respuesta paginada: `{ content: [...], page: { number, size, totalElements, totalPages } }`.
class PagedResponseDto<T> {
  final List<T> content;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;

  const PagedResponseDto({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    final page = json['page'] as Map<String, dynamic>;
    return PagedResponseDto(
      content: (json['content'] as List)
          .map((e) => parseItem(e as Map<String, dynamic>))
          .toList(),
      number: (page['number'] as num).toInt(),
      size: (page['size'] as num).toInt(),
      totalElements: (page['totalElements'] as num).toInt(),
      totalPages: (page['totalPages'] as num).toInt(),
    );
  }

  /// Convierte a dominio aplicando [mapItem] a cada elemento.
  PagedResult<R> toDomain<R>(R Function(T) mapItem) => PagedResult(
        items: content.map(mapItem).toList(),
        number: number,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
      );
}
