import 'crypto_history_item.dart';

class CryptoHistoryResponse {
  const CryptoHistoryResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  final int page;
  final int pageSize;
  final int total;
  final List<CryptoHistoryItem> items;

  int get totalPages {
    if (pageSize <= 0) {
      return 1;
    }
    return (total / pageSize).ceil();
  }

  bool get hasPendingItems => items.any((item) => item.isPending);

  factory CryptoHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return CryptoHistoryResponse(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? rawItems.length,
      total: (json['total'] as num?)?.toInt() ?? rawItems.length,
      items: rawItems
          .whereType<Map>()
          .map((item) => CryptoHistoryItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
