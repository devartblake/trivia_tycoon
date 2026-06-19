library;

// ─────────────────────────────────────────────────────────────────────────────
// GET /store/items/{sku}/disclosure
// ─────────────────────────────────────────────────────────────────────────────

class StoreItemDisclosureDto {
  final String sku;
  final String name;
  final String description;
  final int priceCoins;
  final int priceDiamonds;
  final bool isRefundable;
  final bool isRandomized;
  final int ageMin;
  final bool requiresParentApproval;

  const StoreItemDisclosureDto({
    required this.sku,
    required this.name,
    required this.description,
    required this.priceCoins,
    required this.priceDiamonds,
    required this.isRefundable,
    required this.isRandomized,
    required this.ageMin,
    required this.requiresParentApproval,
  });

  factory StoreItemDisclosureDto.fromJson(Map<String, dynamic> j) =>
      StoreItemDisclosureDto(
        sku: j['sku'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        priceCoins: (j['priceCoins'] as num?)?.toInt() ?? 0,
        priceDiamonds: (j['priceDiamonds'] as num?)?.toInt() ?? 0,
        isRefundable: j['isRefundable'] as bool? ?? false,
        isRandomized: j['isRandomized'] as bool? ?? false,
        ageMin: (j['ageMin'] as num?)?.toInt() ?? 0,
        requiresParentApproval: j['requiresParentApproval'] as bool? ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /store/inventory/{playerId}
// ─────────────────────────────────────────────────────────────────────────────

class PlayerInventoryItemDto {
  final String itemType;
  final int quantity;

  const PlayerInventoryItemDto({
    required this.itemType,
    required this.quantity,
  });

  factory PlayerInventoryItemDto.fromJson(Map<String, dynamic> j) =>
      PlayerInventoryItemDto(
        itemType: j['itemType'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      );
}

class PlayerInventoryDto {
  final String playerId;
  final List<PlayerInventoryItemDto> items;
  final int count;

  const PlayerInventoryDto({
    required this.playerId,
    required this.items,
    required this.count,
  });

  factory PlayerInventoryDto.fromJson(Map<String, dynamic> j) =>
      PlayerInventoryDto(
        playerId: j['playerId']?.toString() ?? '',
        items: (j['items'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(PlayerInventoryItemDto.fromJson)
                .toList() ??
            const [],
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  bool containsItem(String itemType) =>
      items.any((i) => i.itemType.toLowerCase() == itemType.toLowerCase());
}
