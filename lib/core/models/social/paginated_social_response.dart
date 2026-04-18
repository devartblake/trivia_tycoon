class PaginatedSocialResponse<T> {
  const PaginatedSocialResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;

  factory PaginatedSocialResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const <dynamic>[];
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final pageSize = (json['pageSize'] as num?)?.toInt() ?? rawItems.length;
    final total = (json['total'] as num?)?.toInt() ?? rawItems.length;
    final totalPages = (json['totalPages'] as num?)?.toInt() ??
        (pageSize > 0 ? (total / pageSize).ceil() : 1);

    return PaginatedSocialResponse<T>(
      items: rawItems
          .whereType<Map>()
          .map((item) => itemParser(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      page: page,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
    );
  }

  Map<String, dynamic> toJson(Object Function(T item) itemSerializer) {
    return {
      'page': page,
      'pageSize': pageSize,
      'total': total,
      'totalPages': totalPages,
      'items': items.map(itemSerializer).toList(growable: false),
    };
  }
}
