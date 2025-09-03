class PowerUp {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int duration; // in seconds
  final int price;
  final String currency; // 'coins' or 'diamonds'
  final String type;     // ✅ Added this field: 'xp', 'hint', etc.

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

  factory PowerUp.fromJson(Map<String, dynamic> json) {
    return PowerUp(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'] ?? json['icon'] ?? '',
      duration: json['duration'] ?? json['cooldown_seconds'] ?? 60,
      price: json['price'] ?? json['cost_coins'] ?? json['cost_diamonds'] ?? 0,
      currency: json.containsKey('cost_diamonds') ? 'diamonds' : 'coins',
      type: json['type'] ?? 'boost', // ✅ Optional fallback
    );
  }

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

}