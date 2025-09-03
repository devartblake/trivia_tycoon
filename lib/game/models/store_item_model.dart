import 'currency_type.dart';

typedef StoreItem = StoreItemModel;

class StoreItemModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int price;
  final String currency; // 'coins' or 'diamonds'
  final String category; // 'avatar', 'theme', 'power-up', etc.
  final bool isLimited;
  final bool isFeatured;
  final int? duration;
  final String? type; // e.g. 'consumable', 'cosmetic', 'theme'
  final bool owned;
  final int quantity; //  For items like power-ups, default =1
  DateTime? availableUntil;

  StoreItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.price,
    required this.currency,
    required this.category,
    this.isLimited = false,
    this.isFeatured = false,
    this.duration,
    this.type,
    this.owned = false,
    this.quantity = 1,
    this.availableUntil,
  });

  factory StoreItemModel.fromJson(Map<String, dynamic> json) {
    return StoreItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'],
      price: (json['price'] is int) ? json['price'] : (json['price'] as num).round(),
      currency: json['currency'],
      category: json['category'],
      isLimited: json['isLimited'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      duration: json['duration'],
      type: json['type'],
      owned:  json['owned'] ?? false,
      quantity: json['quantity'] ?? 1,
      availableUntil: json['availableUtil'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconPath': iconPath,
    'price': price,
    'currency': currency,
    'category': category,
    'isLimited': isLimited,
    'isFeatured': isFeatured,
    if (duration != null) 'duration': duration,
    'type': type,
    'owned': owned,
    'quantity': quantity,
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
