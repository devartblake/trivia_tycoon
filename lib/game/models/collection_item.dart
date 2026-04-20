/// Model for collectible items in Synaptix
/// These items are earned by mastering different trivia categories
class CollectionItem {
  final String id;
  final String name;
  final String category;
  final String rarity; // legendary, epic, rare, uncommon, common
  final String description;
  final String aiImagePrompt; // For AI image generation
  final int pointValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? iconPath; // Path to generated image asset

  CollectionItem({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.description,
    required this.aiImagePrompt,
    required this.pointValue,
    this.isUnlocked = false,
    this.unlockedAt,
    this.iconPath,
  });

  /// Unlock the collection item
  CollectionItem unlock() {
    return CollectionItem(
      id: id,
      name: name,
      category: category,
      rarity: rarity,
      description: description,
      aiImagePrompt: aiImagePrompt,
      pointValue: pointValue,
      isUnlocked: true,
      unlockedAt: unlockedAt ?? DateTime.now(),
      iconPath: iconPath,
    );
  }

  /// Get rarity color
  String get rarityColor {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return '#FFD700'; // Gold
      case 'epic':
        return '#A335EE'; // Purple
      case 'rare':
        return '#0070DD'; // Blue
      case 'uncommon':
        return '#1EFF00'; // Green
      case 'common':
      default:
        return '#9D9D9D'; // Gray
    }
  }

  /// Get rarity weight for sorting (higher = rarer)
  int get rarityWeight {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 5;
      case 'epic':
        return 4;
      case 'rare':
        return 3;
      case 'uncommon':
        return 2;
      case 'common':
      default:
        return 1;
    }
  }

  /// Copy with method
  CollectionItem copyWith({
    String? id,
    String? name,
    String? category,
    String? rarity,
    String? description,
    String? aiImagePrompt,
    int? pointValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? iconPath,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      description: description ?? this.description,
      aiImagePrompt: aiImagePrompt ?? this.aiImagePrompt,
      pointValue: pointValue ?? this.pointValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rarity': rarity,
      'description': description,
      'aiImagePrompt': aiImagePrompt,
      'pointValue': pointValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'iconPath': iconPath,
    };
  }

  /// Create from JSON
  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      rarity: json['rarity'] as String,
      description: json['description'] as String,
      aiImagePrompt: json['aiImagePrompt'] as String,
      pointValue: json['pointValue'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      iconPath: json['iconPath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionItem &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.rarity == rarity &&
        other.description == description &&
        other.pointValue == pointValue &&
        other.isUnlocked == isUnlocked &&
        other.unlockedAt == unlockedAt &&
        other.iconPath == iconPath;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        category.hashCode ^
        rarity.hashCode ^
        description.hashCode ^
        pointValue.hashCode ^
        isUnlocked.hashCode ^
        unlockedAt.hashCode ^
        iconPath.hashCode;
  }

  @override
  String toString() {
    return 'CollectionItem(id: $id, name: $name, rarity: $rarity, unlocked: $isUnlocked)';
  }
}
