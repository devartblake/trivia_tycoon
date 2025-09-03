import 'dart:ui';
import '../utils/hex_color.dart';

class WheelSegment {
  final String label;
  final Color color;
  final String? imagePath; // Nullable, only used if an image is set
  final int reward;
  final String rewardType;
  final bool isExclusive;
  final int requiredStreak;
  final int requiredCurrency;
  final Map<String, dynamic>? metadata;

  WheelSegment({
    required this.label,
    required this.color,
    this.imagePath,
    required this.reward,
    required this.rewardType,
    this.isExclusive = false,
    this.requiredStreak = 0,
    this.requiredCurrency = 0,
    this.metadata,
  });

  factory WheelSegment.fromJson(Map<String, dynamic> json) {
    return WheelSegment(
      label: json['label'],
      rewardType: json['rewardType'],
      color: HexColor.fromHex(json['color']),
      imagePath: json['imagePath'],
      reward: json['reward'] ?? 0,
      isExclusive: json['isExclusive'] ?? false,
      requiredStreak: json['requiredStreak'] ?? 0,
      requiredCurrency: json['requiredCurrency'] ?? 0,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'rewardType': rewardType,
    'reward': reward,
    'color': color.value.toRadixString(16),
    'imagePath': imagePath,
    'isExclusive': isExclusive,
    'requiredStreak': requiredStreak,
    'requiredCurrency': requiredCurrency,
    'metadata': metadata,
  };
}

