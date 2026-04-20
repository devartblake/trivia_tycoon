import 'currency_type.dart';

typedef StoreItem = StoreItemModel;

class StoreItemModel {
  final String id;
  final String? sku;
  final String name;
  final String description;
  final String iconPath;
  final int price;
  final String currency; // 'coins' or 'diamonds'
  final String category; // 'avatar', 'theme', 'power-up', etc.
  final String? displayPriceLabel;
  final bool requiresExternalCheckout;
  final bool isLimited;
  final bool isFeatured;
  final int? duration;
  final String? type; // e.g. 'consumable', 'cosmetic', 'theme'
  final bool owned;
  final int quantity; //  For items like power-ups, default =1
  final int grantQuantity;
  final int maxPerPlayer;
  final String? mediaKey;
  final int? sortOrder;
  DateTime? availableUntil;

  StoreItemModel({
    required this.id,
    this.sku,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.price,
    required this.currency,
    required this.category,
    this.displayPriceLabel,
    this.requiresExternalCheckout = false,
    this.isLimited = false,
    this.isFeatured = false,
    this.duration,
    this.type,
    this.owned = false,
    this.quantity = 1,
    this.grantQuantity = 1,
    this.maxPerPlayer = 0,
    this.mediaKey,
    this.sortOrder,
    this.availableUntil,
  });

  factory StoreItemModel.fromJson(Map<String, dynamic> json) {
    return StoreItemModel(
      id: json['id'],
      sku: json['sku']?.toString(),
      name: json['name'],
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      price: (json['price'] is int)
          ? json['price']
          : (json['price'] as num).round(),
      currency: json['currency'],
      category: json['category'],
      displayPriceLabel: json['displayPriceLabel']?.toString(),
      requiresExternalCheckout: json['requiresExternalCheckout'] == true,
      isLimited: json['isLimited'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      duration: json['duration'],
      type: json['type'],
      owned: json['owned'] ?? false,
      quantity: json['quantity'] ?? 1,
      grantQuantity: json['grantQuantity'] ?? 1,
      maxPerPlayer: json['maxPerPlayer'] ?? 0,
      mediaKey: json['mediaKey']?.toString(),
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : null,
      availableUntil: json['availableUtil'],
    );
  }

  factory StoreItemModel.fromStoreCatalog(
    Map<String, dynamic> json, {
    StoreItemModel? displayItem,
    bool owned = false,
  }) {
    final priceCoins = (json['priceCoins'] as num?)?.round() ?? 0;
    final priceDiamonds = (json['priceDiamonds'] as num?)?.round() ?? 0;
    final mappedPrice = priceCoins > 0
        ? priceCoins
        : priceDiamonds > 0
            ? priceDiamonds
            : displayItem?.price ?? 0;
    final mappedCurrency = priceCoins > 0
        ? 'coins'
        : priceDiamonds > 0
            ? 'diamonds'
            : displayItem?.currency ?? 'usd';
    final externalCheckout =
        priceCoins == 0 && priceDiamonds == 0 && mappedCurrency == 'usd';

    return StoreItemModel(
      id: json['id']?.toString() ?? json['sku']?.toString() ?? '',
      sku: json['sku']?.toString(),
      name: json['name']?.toString() ?? displayItem?.name ?? 'Store Item',
      description:
          json['description']?.toString() ?? displayItem?.description ?? '',
      iconPath: displayItem?.iconPath ??
          _defaultIconPathForCategory(json['itemType']?.toString()),
      price: mappedPrice,
      currency: mappedCurrency,
      category:
          json['itemType']?.toString() ?? displayItem?.category ?? 'store',
      displayPriceLabel: displayItem?.displayPriceLabel ??
          _buildDisplayPriceLabel(
            priceCoins: priceCoins,
            priceDiamonds: priceDiamonds,
            fallback: displayItem,
          ),
      requiresExternalCheckout:
          json['requiresExternalCheckout'] == true || externalCheckout,
      isLimited: displayItem?.isLimited ?? false,
      isFeatured: displayItem?.isFeatured ?? false,
      duration: displayItem?.duration,
      type: displayItem?.type,
      owned: owned || displayItem?.owned == true,
      quantity: displayItem?.quantity ?? 1,
      grantQuantity: (json['grantQuantity'] as num?)?.round() ?? 1,
      maxPerPlayer: (json['maxPerPlayer'] as num?)?.round() ?? 0,
      mediaKey: json['mediaKey']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.round(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'name': name,
        'description': description,
        'iconPath': iconPath,
        'price': price,
        'currency': currency,
        'category': category,
        'displayPriceLabel': displayPriceLabel,
        'requiresExternalCheckout': requiresExternalCheckout,
        'isLimited': isLimited,
        'isFeatured': isFeatured,
        if (duration != null) 'duration': duration,
        'type': type,
        'owned': owned,
        'quantity': quantity,
        'grantQuantity': grantQuantity,
        'maxPerPlayer': maxPerPlayer,
        'mediaKey': mediaKey,
        'sortOrder': sortOrder,
        'availableUtil': availableUntil,
      };

  CurrencyType get currencyType {
    switch (currency.toLowerCase()) {
      case 'diamonds':
        return CurrencyType.diamonds;
      case 'coins':
      default:
        return CurrencyType.coins;
    }
  }
}

String? _buildDisplayPriceLabel({
  required int priceCoins,
  required int priceDiamonds,
  StoreItemModel? fallback,
}) {
  if (priceCoins > 0) return '$priceCoins coins';
  if (priceDiamonds > 0) return '$priceDiamonds diamonds';
  if (fallback?.displayPriceLabel != null) return fallback!.displayPriceLabel;
  if (fallback != null && fallback.price > 0) {
    if (fallback.currency.toLowerCase() == 'usd') {
      return '\$${fallback.price.toString()}';
    }
    return '${fallback.price} ${fallback.currency}';
  }
  return 'Checkout';
}

String _defaultIconPathForCategory(String? category) {
  switch ((category ?? '').toLowerCase()) {
    case 'powerup':
    case 'power-up':
      return 'assets/icons/store/power-up_xp.png';
    case 'avatar':
      return 'assets/icons/store/avatars/dragon.png';
    case 'theme':
      return 'assets/icons/store/themes/green_icon.png';
    case 'currency':
      return 'assets/icons/store/coins_100.png';
    default:
      return '';
  }
}
