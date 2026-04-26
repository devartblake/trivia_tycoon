import 'package:flutter/material.dart';
import 'store_stock_ui_model.dart';

/// A single item in the daily rotating store.
class DailyStoreItem {
  final String sku;
  final String title;
  final String description;
  final int price;
  final String currency;
  final String? iconPath;
  final String? category;
  final bool owned;
  final StoreStockState stock;

  const DailyStoreItem({
    required this.sku,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    this.iconPath,
    this.category,
    this.owned = false,
    this.stock = StoreStockState.unlimited,
  });

  factory DailyStoreItem.fromJson(Map<String, dynamic> json) {
    // Backend sends priceCoins/priceDiamonds (flat). Fallback to legacy price/currency.
    final priceCoins = (json['priceCoins'] as num?)?.toInt();
    final price = priceCoins ?? (json['price'] as num?)?.toInt() ?? 0;
    final currency = priceCoins != null ? 'coins' : (json['currency'] as String? ?? 'coins');

    // Build stock state from flat backend fields or legacy nested stock object.
    final StoreStockState stock;
    if (json['stock'] != null) {
      stock = StoreStockState.fromJson(Map<String, dynamic>.from(json['stock'] as Map));
    } else {
      stock = StoreStockState(
        policyType: (json['resetInterval'] as String?) != null ? 'per_user' : 'unlimited',
        maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
        remainingQuantity: (json['remainingQuantity'] as num?)?.toInt(),
        resetInterval: json['resetInterval'] as String?,
        nextResetAt: json['nextResetAt'] != null
            ? DateTime.tryParse(json['nextResetAt'] as String)
            : null,
        isSoldOut: json['soldOut'] as bool? ?? false,
        isUnlimited: (json['remainingQuantity'] as num?)?.toInt() == -1 ||
            json['resetInterval'] == null,
      );
    }

    return DailyStoreItem(
      sku: json['sku'] as String? ?? json['id'] as String? ?? '',
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: price,
      currency: currency,
      iconPath: json['iconPath'] as String?,
      category: json['itemType'] as String? ?? json['category'] as String?,
      owned: json['owned'] as bool? ?? false,
      stock: stock,
    );
  }

  bool get isFree => price == 0;
  bool get isCoins => currency == 'coins';
}

/// The full daily store payload returned by `GET /store/daily`.
///
/// Backend and Sidecar are responsible for rotating items at [nextResetAt].
/// All clients share the same [nextResetAt]; the Flutter app displays a live
/// countdown and invalidates [dailyStoreProvider] once the timer fires.
class DailyStoreData {
  final List<DailyStoreItem> items;

  /// UTC timestamp of the next global restock — same for every player.
  final DateTime nextResetAt;

  /// How long each daily cycle lasts in seconds (typically 86400).
  final int resetIntervalSeconds;

  /// Optional banner copy shown above the item grid.
  final String? bannerMessage;

  const DailyStoreData({
    required this.items,
    required this.nextResetAt,
    required this.resetIntervalSeconds,
    this.bannerMessage,
  });

  Duration get timeUntilReset => nextResetAt.difference(DateTime.now().toUtc());
  bool get isExpired => timeUntilReset.isNegative;

  factory DailyStoreData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    // Backend sends "resetsAt"; fallback to legacy "nextResetAt".
    final resetRaw = json['resetsAt'] as String? ?? json['nextResetAt'] as String?;
    final resetAt = resetRaw != null
        ? DateTime.parse(resetRaw).toUtc()
        : DateTime.now().toUtc().add(const Duration(hours: 24));

    return DailyStoreData(
      items: rawItems
          .whereType<Map>()
          .map((i) => DailyStoreItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      nextResetAt: resetAt,
      resetIntervalSeconds: (json['resetIntervalSeconds'] as num?)?.toInt() ?? 86400,
      bannerMessage: json['bannerMessage'] as String?,
    );
  }

  static DailyStoreData get fallback => DailyStoreData(
        items: const [
          DailyStoreItem(
            sku: 'daily:double-xp-30m',
            title: 'Double XP (30 min)',
            description: 'Earn 2× XP on every correct answer for 30 minutes.',
            price: 200,
            currency: 'coins',
            category: 'power_up',
          ),
          DailyStoreItem(
            sku: 'daily:hint-pack-5',
            title: 'Hint Pack ×5',
            description: 'Five extra hints to use whenever you need them.',
            price: 150,
            currency: 'coins',
            category: 'power_up',
          ),
          DailyStoreItem(
            sku: 'daily:shield-x3',
            title: 'Shield ×3',
            description: 'Block three wrong answers from counting against you.',
            price: 300,
            currency: 'coins',
            category: 'power_up',
          ),
          DailyStoreItem(
            sku: 'daily:avatar-frame-neon',
            title: 'Neon Avatar Frame',
            description: 'Exclusive neon glow frame — available today only.',
            price: 500,
            currency: 'coins',
            category: 'cosmetic',
          ),
        ],
        nextResetAt: _tomorrowMidnightUtc(),
        resetIntervalSeconds: 86400,
        bannerMessage: 'Daily items refresh every day at midnight UTC.',
      );

  static DateTime _tomorrowMidnightUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1);
  }
}

/// Maps a [DailyStoreItem] category string to an icon.
IconData dailyItemIcon(String? category) {
  return switch (category) {
    'power_up' => Icons.bolt,
    'cosmetic' => Icons.palette,
    'avatar' => Icons.face,
    'bundle' => Icons.card_giftcard,
    'currency' => Icons.monetization_on,
    _ => Icons.auto_awesome,
  };
}

/// Maps a [DailyStoreItem] category string to a colour.
Color dailyItemColor(String? category) {
  return switch (category) {
    'power_up' => const Color(0xFF8B5CF6),
    'cosmetic' => const Color(0xFFEC4899),
    'avatar' => const Color(0xFF10B981),
    'bundle' => const Color(0xFFF59E0B),
    'currency' => const Color(0xFF6366F1),
    _ => const Color(0xFF64748B),
  };
}
