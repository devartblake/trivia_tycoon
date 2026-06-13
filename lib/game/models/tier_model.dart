import 'package:flutter/material.dart';

class TierModel {
  final int id;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final int requiredXP;
  final int requiredLevel;
  final List<String> rewards;
  final bool isUnlocked;
  final bool isCurrent;
  final DateTime? unlockedAt;

  const TierModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.requiredXP,
    required this.requiredLevel,
    required this.rewards,
    this.isUnlocked = false,
    this.isCurrent = false,
    this.unlockedAt,
  });

  TierModel copyWith({
    int? id,
    String? name,
    String? description,
    IconData? icon,
    Color? primaryColor,
    Color? secondaryColor,
    int? requiredXP,
    int? requiredLevel,
    List<String>? rewards,
    bool? isUnlocked,
    bool? isCurrent,
    DateTime? unlockedAt,
  }) {
    return TierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      requiredXP: requiredXP ?? this.requiredXP,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      rewards: rewards ?? this.rewards,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCurrent: isCurrent ?? this.isCurrent,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _iconKey(icon),
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'requiredXP': requiredXP,
      'requiredLevel': requiredLevel,
      'rewards': rewards,
      'isUnlocked': isUnlocked,
      'isCurrent': isCurrent,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory TierModel.fromJson(Map<String, dynamic> json) {
    return TierModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: _parseIcon(json['icon']),
      primaryColor: Color(json['primaryColor']),
      secondaryColor: Color(json['secondaryColor']),
      requiredXP: json['requiredXP'],
      requiredLevel: json['requiredLevel'],
      rewards: List<String>.from(json['rewards']),
      isUnlocked: json['isUnlocked'] ?? false,
      isCurrent: json['isCurrent'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  static IconData _parseIcon(Object? value) {
    if (value is String) {
      return _iconForKey(value);
    }

    if (value is int) {
      return _iconForCodePoint(value);
    }

    return Icons.emoji_events;
  }

  static IconData _iconForKey(String key) {
    switch (key) {
      case 'star_border':
        return Icons.star_border;
      case 'star':
        return Icons.star;
      case 'shield':
        return Icons.shield;
      case 'diamond':
        return Icons.diamond;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events_outlined':
        return Icons.emoji_events_outlined;
      case 'workspace_premium_outlined':
        return Icons.workspace_premium_outlined;
      case 'monetization_on_outlined':
        return Icons.monetization_on_outlined;
      case 'emoji_events':
      default:
        return Icons.emoji_events;
    }
  }

  static IconData _iconForCodePoint(int codePoint) {
    if (codePoint == Icons.star_border.codePoint) {
      return Icons.star_border;
    }
    if (codePoint == Icons.star.codePoint) {
      return Icons.star;
    }
    if (codePoint == Icons.shield.codePoint) {
      return Icons.shield;
    }
    if (codePoint == Icons.diamond.codePoint) {
      return Icons.diamond;
    }
    if (codePoint == Icons.workspace_premium.codePoint) {
      return Icons.workspace_premium;
    }
    if (codePoint == Icons.military_tech.codePoint) {
      return Icons.military_tech;
    }
    if (codePoint == Icons.emoji_events_outlined.codePoint) {
      return Icons.emoji_events_outlined;
    }
    if (codePoint == Icons.workspace_premium_outlined.codePoint) {
      return Icons.workspace_premium_outlined;
    }
    if (codePoint == Icons.monetization_on_outlined.codePoint) {
      return Icons.monetization_on_outlined;
    }

    return Icons.emoji_events;
  }

  static String _iconKey(IconData icon) {
    final codePoint = icon.codePoint;

    if (codePoint == Icons.star_border.codePoint) {
      return 'star_border';
    }
    if (codePoint == Icons.star.codePoint) {
      return 'star';
    }
    if (codePoint == Icons.shield.codePoint) {
      return 'shield';
    }
    if (codePoint == Icons.diamond.codePoint) {
      return 'diamond';
    }
    if (codePoint == Icons.workspace_premium.codePoint) {
      return 'workspace_premium';
    }
    if (codePoint == Icons.military_tech.codePoint) {
      return 'military_tech';
    }
    if (codePoint == Icons.emoji_events_outlined.codePoint) {
      return 'emoji_events_outlined';
    }
    if (codePoint == Icons.workspace_premium_outlined.codePoint) {
      return 'workspace_premium_outlined';
    }
    if (codePoint == Icons.monetization_on_outlined.codePoint) {
      return 'monetization_on_outlined';
    }

    return 'emoji_events';
  }

  LinearGradient get gradient {
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
