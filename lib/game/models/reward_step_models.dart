import 'package:flutter/material.dart';

/// Represents a reward milestone in the reward progression system
class RewardStep {
  final double pointValue;
  final IconData icon;
  final Color backgroundColor;
  final int quantity;
  final String description;
  final RewardType type;
  final String? imageUrl;
  final bool isLocked;
  final DateTime? unlockDate;
  final Map<String, dynamic>? metadata;

  const RewardStep({
    required this.pointValue,
    required this.icon,
    required this.backgroundColor,
    this.quantity = 1,
    this.description = '',
    this.type = RewardType.coins,
    this.imageUrl,
    this.isLocked = false,
    this.unlockDate,
    this.metadata,
  });

  /// Check if this reward is currently unlocked
  bool get isUnlocked =>
      !isLocked && (unlockDate == null || DateTime.now().isAfter(unlockDate!));

  /// Get display text for the reward
  String get displayText {
    if (quantity > 1) {
      return '$description x$quantity';
    }
    return description;
  }

  /// Get formatted point value
  String get formattedPoints {
    if (pointValue >= 1000) {
      return '${(pointValue / 1000).toStringAsFixed(1)}k';
    }
    return pointValue.toStringAsFixed(0);
  }

  /// Create a copy with updated values
  RewardStep copyWith({
    double? pointValue,
    IconData? icon,
    Color? backgroundColor,
    int? quantity,
    String? description,
    RewardType? type,
    String? imageUrl,
    bool? isLocked,
    DateTime? unlockDate,
    Map<String, dynamic>? metadata,
  }) {
    return RewardStep(
      pointValue: pointValue ?? this.pointValue,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isLocked: isLocked ?? this.isLocked,
      unlockDate: unlockDate ?? this.unlockDate,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointValue': pointValue,
      'quantity': quantity,
      'description': description,
      'type': type.name,
      'imageUrl': imageUrl,
      'isLocked': isLocked,
      'unlockDate': unlockDate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory RewardStep.fromJson(Map<String, dynamic> json) {
    return RewardStep(
      pointValue: (json['pointValue'] as num).toDouble(),
      icon: Icons.card_giftcard, // Default icon, customize as needed
      backgroundColor: Colors.orange, // Default color, customize as needed
      quantity: json['quantity'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RewardType.coins,
      ),
      imageUrl: json['imageUrl'] as String?,
      isLocked: json['isLocked'] as bool? ?? false,
      unlockDate: json['unlockDate'] != null
          ? DateTime.parse(json['unlockDate'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Types of rewards available in the system
enum RewardType {
  coins,
  gems,
  powerUp,
  badge,
  avatar,
  theme,
  mysteryBox,
  giftCard,
  premiumAccess,
  xpBoost,
  custom;

  String get displayName {
    switch (this) {
      case RewardType.coins:
        return 'Coins';
      case RewardType.gems:
        return 'Gems';
      case RewardType.powerUp:
        return 'Power-Up';
      case RewardType.badge:
        return 'Badge';
      case RewardType.avatar:
        return 'Avatar';
      case RewardType.theme:
        return 'Theme';
      case RewardType.mysteryBox:
        return 'Mystery Box';
      case RewardType.giftCard:
        return 'Gift Card';
      case RewardType.premiumAccess:
        return 'Premium Access';
      case RewardType.xpBoost:
        return 'XP Boost';
      case RewardType.custom:
        return 'Reward';
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case RewardType.coins:
        return Icons.monetization_on;
      case RewardType.gems:
        return Icons.diamond;
      case RewardType.powerUp:
        return Icons.flash_on;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.avatar:
        return Icons.face;
      case RewardType.theme:
        return Icons.palette;
      case RewardType.mysteryBox:
        return Icons.inventory_2;
      case RewardType.giftCard:
        return Icons.card_giftcard;
      case RewardType.premiumAccess:
        return Icons.stars;
      case RewardType.xpBoost:
        return Icons.trending_up;
      case RewardType.custom:
        return Icons.redeem;
    }
  }

  Color get defaultColor {
    switch (this) {
      case RewardType.coins:
        return const Color(0xFFFFA500);
      case RewardType.gems:
        return const Color(0xFF9C27B0);
      case RewardType.powerUp:
        return const Color(0xFF2196F3);
      case RewardType.badge:
        return const Color(0xFFF44336);
      case RewardType.avatar:
        return const Color(0xFF4CAF50);
      case RewardType.theme:
        return const Color(0xFFE91E63);
      case RewardType.mysteryBox:
        return const Color(0xFF795548);
      case RewardType.giftCard:
        return const Color(0xFFFF9800);
      case RewardType.premiumAccess:
        return const Color(0xFFFFD700);
      case RewardType.xpBoost:
        return const Color(0xFF00BCD4);
      case RewardType.custom:
        return const Color(0xFF607D8B);
    }
  }
}
