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
      'icon': icon.codePoint,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
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
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
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

  LinearGradient get gradient {
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
