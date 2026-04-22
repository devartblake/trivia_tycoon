import 'package:flutter/foundation.dart';

/// Availability sub-object returned per store item.
class StoreAvailabilityState {
  final bool isVisible;
  final bool isPurchasable;
  final bool requiresPremium;
  final bool isFlashSale;
  final DateTime? saleEndsAt;

  const StoreAvailabilityState({
    this.isVisible = true,
    this.isPurchasable = true,
    this.requiresPremium = false,
    this.isFlashSale = false,
    this.saleEndsAt,
  });

  factory StoreAvailabilityState.fromJson(Map<String, dynamic> json) {
    return StoreAvailabilityState(
      isVisible: json['isVisible'] as bool? ?? true,
      isPurchasable: json['isPurchasable'] as bool? ?? true,
      requiresPremium: json['requiresPremium'] as bool? ?? false,
      isFlashSale: json['isFlashSale'] as bool? ?? false,
      saleEndsAt: json['saleEndsAt'] != null
          ? DateTime.tryParse(json['saleEndsAt'].toString())
          : null,
    );
  }

  static const StoreAvailabilityState always = StoreAvailabilityState();
}

/// Stock sub-object returned per store item.
class StoreStockState {
  final String policyType; // unlimited | per_user | one_time_purchase | time_limited | event_limited
  final int? maxQuantity;
  final int usedQuantity;
  final int? remainingQuantity;
  final String? resetInterval; // hourly | daily | weekly | seasonal | none
  final DateTime? lastResetAt;
  final DateTime? nextResetAt;
  final bool isSoldOut;
  final bool isUnlimited;
  final bool isOneTimePurchase;
  final DateTime? expiresAt;

  const StoreStockState({
    this.policyType = 'unlimited',
    this.maxQuantity,
    this.usedQuantity = 0,
    this.remainingQuantity,
    this.resetInterval,
    this.lastResetAt,
    this.nextResetAt,
    this.isSoldOut = false,
    this.isUnlimited = true,
    this.isOneTimePurchase = false,
    this.expiresAt,
  });

  factory StoreStockState.fromJson(Map<String, dynamic> json) {
    return StoreStockState(
      policyType: (json['policyType'] as String?) ?? 'unlimited',
      maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
      usedQuantity: (json['usedQuantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt(),
      resetInterval: json['resetInterval'] as String?,
      lastResetAt: json['lastResetAt'] != null
          ? DateTime.tryParse(json['lastResetAt'].toString())
          : null,
      nextResetAt: json['nextResetAt'] != null
          ? DateTime.tryParse(json['nextResetAt'].toString())
          : null,
      isSoldOut: json['isSoldOut'] as bool? ?? false,
      isUnlimited: json['isUnlimited'] as bool? ?? true,
      isOneTimePurchase: json['isOneTimePurchase'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now().toUtc());
  }

  bool get hasUrgentStock {
    if (isSoldOut || isUnlimited) return false;
    final remaining = remainingQuantity;
    if (remaining != null && remaining <= 1) return true;
    final reset = nextResetAt ?? expiresAt;
    if (reset != null) {
      final remaining = reset.difference(DateTime.now().toUtc());
      return remaining.inMinutes < 60;
    }
    return false;
  }

  static const StoreStockState unlimited = StoreStockState();
}

/// Player-scoped store item combining catalog data with personalised stock state.
/// Populated from GET /store/catalog/{playerId}.
@immutable
class PlayerStoreItem {
  final String sku;
  final String title;
  final String description;
  final String type;
  final int price;
  final String currency;
  final StoreStockState stock;
  final StoreAvailabilityState availability;
  final String? iconPath;
  final String? thumbnailUrl;
  final bool owned;
  final bool isFeatured;

  const PlayerStoreItem({
    required this.sku,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.currency,
    this.stock = StoreStockState.unlimited,
    this.availability = StoreAvailabilityState.always,
    this.iconPath,
    this.thumbnailUrl,
    this.owned = false,
    this.isFeatured = false,
  });

  factory PlayerStoreItem.fromJson(Map<String, dynamic> json) {
    final stockJson = json['stock'];
    final availJson = json['availability'];
    return PlayerStoreItem(
      sku: (json['sku'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'coins').toString(),
      stock: stockJson is Map
          ? StoreStockState.fromJson(Map<String, dynamic>.from(stockJson))
          : const StoreStockState(),
      availability: availJson is Map
          ? StoreAvailabilityState.fromJson(
              Map<String, dynamic>.from(availJson))
          : const StoreAvailabilityState(),
      iconPath: json['iconPath']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      owned: json['owned'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  bool get isFree => price == 0 || currency == 'free';

  bool get canPurchase {
    if (!availability.isPurchasable) return false;
    if (stock.isSoldOut) return false;
    if (stock.isExpired) return false;
    if (stock.isOneTimePurchase && owned) return false;
    return true;
  }
}
