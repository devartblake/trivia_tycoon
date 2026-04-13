import '../models/store_item_model.dart';

class PowerUp {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int duration; // in seconds
  final int price;
  final String currency; // 'coins' or 'diamonds'
  final String type;     // 'xp', 'hint', 'eliminate', 'boost', 'shield', etc.

  PowerUp({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.duration,
    required this.price,
    required this.currency,
    required this.type,
  });

  /// Create PowerUp from JSON
  factory PowerUp.fromJson(Map<String, dynamic> json) {
    return PowerUp(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'] ?? json['icon'] ?? '',
      duration: json['duration'] ?? json['cooldown_seconds'] ?? 60,
      price: json['price'] ?? json['cost_coins'] ?? json['cost_diamonds'] ?? 0,
      currency: json.containsKey('cost_diamonds') ? 'diamonds' : 'coins',
      type: json['type'] ?? 'boost',
    );
  }

  /// Create PowerUp from StoreItemModel (fixes type casting issues)
  factory PowerUp.fromStoreItem(StoreItemModel item) {
    return PowerUp(
      id: item.id,
      name: item.name,
      description: item.description,
      iconPath: item.iconPath,
      duration: item.duration ?? 0,
      price: item.price,
      currency: item.currency,
      type: item.type ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconPath': iconPath,
    'duration': duration,
    'price': price,
    'currency': currency,
    'type': type,
  };

  /// Create empty/none power-up
  factory PowerUp.none() => PowerUp(
    id: 'none',
    name: 'None',
    description: '',
    iconPath: '',
    duration: 0,
    price: 0,
    currency: '',
    type: 'none',
  );

  /// Check if this is the "none" power-up
  bool get isNone => id == 'none';

  /// Check if this power-up is currently active
  bool isActive(int? remainingTime) {
    return remainingTime != null && remainingTime > 0;
  }

  /// Get formatted duration string (e.g., "5m 30s")
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Create a copy with modified fields
  PowerUp copyWith({
    String? id,
    String? name,
    String? description,
    String? iconPath,
    int? duration,
    int? price,
    String? currency,
    String? type,
  }) {
    return PowerUp(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'PowerUp(id: $id, name: $name, type: $type, duration: ${formattedDuration})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PowerUp &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, duration);
  }
}
