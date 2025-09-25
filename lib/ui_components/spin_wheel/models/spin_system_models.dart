import 'dart:convert';
import 'package:flutter/material.dart';

/// Enhanced PrizeEntry with additional metadata and validation
class PrizeEntry {
  final String id;
  final String prize;
  final DateTime timestamp;
  final String? description;
  final String? category;
  final Map<String, dynamic>? metadata;
  final bool isClaimed;
  final DateTime? claimedAt;

  const PrizeEntry({
    required this.id,
    required this.prize,
    required this.timestamp,
    this.description,
    this.category,
    this.metadata,
    this.isClaimed = false,
    this.claimedAt,
  });

  /// Create a copy with updated fields
  PrizeEntry copyWith({
    String? id,
    String? prize,
    DateTime? timestamp,
    String? description,
    String? category,
    Map<String, dynamic>? metadata,
    bool? isClaimed,
    DateTime? claimedAt,
  }) {
    return PrizeEntry(
      id: id ?? this.id,
      prize: prize ?? this.prize,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      isClaimed: isClaimed ?? this.isClaimed,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  /// Mark prize as claimed
  PrizeEntry claim() {
    return copyWith(
      isClaimed: true,
      claimedAt: DateTime.now(),
    );
  }

  /// Check if prize is expired (optional expiration logic)
  bool isExpired({Duration? expiryDuration}) {
    if (expiryDuration == null) return false;
    return DateTime.now().difference(timestamp) > expiryDuration;
  }

  /// Get time since prize was won
  Duration get timeSince => DateTime.now().difference(timestamp);

  /// Get formatted time since string
  String get timeSinceFormatted {
    final duration = timeSince;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'prize': prize,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'category': category,
    'metadata': metadata,
    'isClaimed': isClaimed,
    'claimedAt': claimedAt?.toIso8601String(),
  };

  /// Create from JSON with validation
  factory PrizeEntry.fromJson(Map<String, dynamic> json) {
    try {
      return PrizeEntry(
        id: json['id'] ?? '',
        prize: json['prize'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'],
        category: json['category'],
        metadata: json['metadata'] as Map<String, dynamic>?,
        isClaimed: json['isClaimed'] ?? false,
        claimedAt: json['claimedAt'] != null
            ? DateTime.parse(json['claimedAt'])
            : null,
      );
    } catch (e) {
      throw FormatException('Invalid PrizeEntry JSON: $e');
    }
  }

  /// Encode list of prizes to JSON string
  static String encodeList(List<PrizeEntry> entries) {
    try {
      return json.encode(entries.map((e) => e.toJson()).toList());
    } catch (e) {
      throw FormatException('Failed to encode PrizeEntry list: $e');
    }
  }

  /// Decode JSON string to list of prizes
  static List<PrizeEntry> decodeList(String raw) {
    try {
      final List decoded = json.decode(raw);
      return decoded.map((e) => PrizeEntry.fromJson(e)).toList();
    } catch (e) {
      throw FormatException('Failed to decode PrizeEntry list: $e');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PrizeEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PrizeEntry(id: $id, prize: $prize, timestamp: $timestamp)';
}

/// Enhanced SpinResult with better validation and additional features
class SpinResult {
  final String id;
  final String label;
  final String? imagePath;
  final int reward;
  final String? rewardType;
  final String? description;
  final DateTime timestamp;
  final Duration? spinDuration;
  final double? spinVelocity;
  final int? segmentIndex;
  final Map<String, dynamic>? metadata;
  final bool isJackpot;
  final bool isRare;

  const SpinResult({
    required this.id,
    required this.label,
    this.imagePath,
    required this.reward,
    this.rewardType,
    this.description,
    required this.timestamp,
    this.spinDuration,
    this.spinVelocity,
    this.segmentIndex,
    this.metadata,
    this.isJackpot = false,
    this.isRare = false,
  });

  /// Create a copy with updated fields
  SpinResult copyWith({
    String? id,
    String? label,
    String? imagePath,
    int? reward,
    String? rewardType,
    String? description,
    DateTime? timestamp,
    Duration? spinDuration,
    double? spinVelocity,
    int? segmentIndex,
    Map<String, dynamic>? metadata,
    bool? isJackpot,
    bool? isRare,
  }) {
    return SpinResult(
      id: id ?? this.id,
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      reward: reward ?? this.reward,
      rewardType: rewardType ?? this.rewardType,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      spinDuration: spinDuration ?? this.spinDuration,
      spinVelocity: spinVelocity ?? this.spinVelocity,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      metadata: metadata ?? this.metadata,
      isJackpot: isJackpot ?? this.isJackpot,
      isRare: isRare ?? this.isRare,
    );
  }

  /// Check if this is a premium reward
  bool get isPremium {
    return isJackpot ||
        isRare ||
        ['premium', 'gems', 'legendary'].contains(rewardType?.toLowerCase());
  }

  /// Get reward category color
  Color get categoryColor {
    switch (rewardType?.toLowerCase()) {
      case 'coins':
      case 'currency':
        return Colors.amber;
      case 'gems':
      case 'premium':
        return Colors.purple;
      case 'rare':
        return Colors.orange;
      case 'legendary':
        return Colors.pink;
      case 'jackpot':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Get reward emoji
  String get emoji {
    switch (rewardType?.toLowerCase()) {
      case 'coins':
      case 'currency':
        return '🪙';
      case 'gems':
      case 'premium':
        return '💎';
      case 'rare':
        return '✨';
      case 'legendary':
        return '🌟';
      case 'jackpot':
        return '🎉';
      default:
        return '🎁';
    }
  }

  /// Get formatted reward amount
  String get formattedReward {
    if (reward >= 1000000) {
      return '${(reward / 1000000).toStringAsFixed(1)}M';
    } else if (reward >= 1000) {
      return '${(reward / 1000).toStringAsFixed(1)}K';
    }
    return reward.toString();
  }

  /// Convert to PrizeEntry for history tracking
  PrizeEntry toPrizeEntry() {
    return PrizeEntry(
      id: id,
      prize: label,
      timestamp: timestamp,
      description: description,
      category: rewardType,
      metadata: {
        'reward': reward,
        'imagePath': imagePath,
        'spinDuration': spinDuration?.inMilliseconds,
        'spinVelocity': spinVelocity,
        'segmentIndex': segmentIndex,
        'isJackpot': isJackpot,
        'isRare': isRare,
        ...?metadata,
      },
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'imagePath': imagePath,
    'reward': reward,
    'rewardType': rewardType,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'spinDuration': spinDuration?.inMilliseconds,
    'spinVelocity': spinVelocity,
    'segmentIndex': segmentIndex,
    'metadata': metadata,
    'isJackpot': isJackpot,
    'isRare': isRare,
  };

  /// Create from JSON with validation
  factory SpinResult.fromJson(Map<String, dynamic> json) {
    try {
      return SpinResult(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        imagePath: json['imagePath'],
        reward: json['reward'] ?? 0,
        rewardType: json['rewardType'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
        spinDuration: json['spinDuration'] != null
            ? Duration(milliseconds: json['spinDuration'])
            : null,
        spinVelocity: json['spinVelocity']?.toDouble(),
        segmentIndex: json['segmentIndex'],
        metadata: json['metadata'] as Map<String, dynamic>?,
        isJackpot: json['isJackpot'] ?? false,
        isRare: json['isRare'] ?? false,
      );
    } catch (e) {
      throw FormatException('Invalid SpinResult JSON: $e');
    }
  }

  /// Encode list to JSON string
  static String encodeList(List<SpinResult> results) {
    try {
      return json.encode(results.map((e) => e.toJson()).toList());
    } catch (e) {
      throw FormatException('Failed to encode SpinResult list: $e');
    }
  }

  /// Decode JSON string to list
  static List<SpinResult> decodeList(String raw) {
    try {
      final List decoded = json.decode(raw);
      return decoded.map((e) => SpinResult.fromJson(e)).toList();
    } catch (e) {
      throw FormatException('Failed to decode SpinResult list: $e');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpinResult && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SpinResult(id: $id, label: $label, reward: $reward)';
}

/// Enhanced WheelSegment with validation and additional features
class WheelSegment {
  final String id;
  final String label;
  final Color color;
  final String? imagePath;
  final int reward;
  final String rewardType;
  final bool isExclusive;
  final int requiredStreak;
  final int requiredCurrency;
  final String? description;
  final double probability;
  final Map<String, dynamic>? metadata;
  final bool isEnabled;
  final DateTime? enabledUntil;

  const WheelSegment({
    required this.id,
    required this.label,
    required this.color,
    this.imagePath,
    required this.reward,
    required this.rewardType,
    this.isExclusive = false,
    this.requiredStreak = 0,
    this.requiredCurrency = 0,
    this.description,
    this.probability = 1.0,
    this.metadata,
    this.isEnabled = true,
    this.enabledUntil,
  });

  /// Create a copy with updated fields
  WheelSegment copyWith({
    String? id,
    String? label,
    Color? color,
    String? imagePath,
    int? reward,
    String? rewardType,
    bool? isExclusive,
    int? requiredStreak,
    int? requiredCurrency,
    String? description,
    double? probability,
    Map<String, dynamic>? metadata,
    bool? isEnabled,
    DateTime? enabledUntil,
  }) {
    return WheelSegment(
      id: id ?? this.id,
      label: label ?? this.label,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      reward: reward ?? this.reward,
      rewardType: rewardType ?? this.rewardType,
      isExclusive: isExclusive ?? this.isExclusive,
      requiredStreak: requiredStreak ?? this.requiredStreak,
      requiredCurrency: requiredCurrency ?? this.requiredCurrency,
      description: description ?? this.description,
      probability: probability ?? this.probability,
      metadata: metadata ?? this.metadata,
      isEnabled: isEnabled ?? this.isEnabled,
      enabledUntil: enabledUntil ?? this.enabledUntil,
    );
  }

  /// Check if segment is currently available
  bool get isAvailable {
    if (!isEnabled) return false;
    if (enabledUntil != null && DateTime.now().isAfter(enabledUntil!)) {
      return false;
    }
    return true;
  }

  /// Check if user can access this segment
  bool canAccess({int userStreak = 0, int userCurrency = 0}) {
    if (!isAvailable) return false;
    if (!isExclusive) return true;

    return userStreak >= requiredStreak && userCurrency >= requiredCurrency;
  }

  /// Get rarity level
  SegmentRarity get rarity {
    switch (rewardType.toLowerCase()) {
      case 'legendary':
      case 'jackpot':
        return SegmentRarity.legendary;
      case 'rare':
      case 'premium':
        return SegmentRarity.rare;
      case 'uncommon':
        return SegmentRarity.uncommon;
      default:
        return SegmentRarity.common;
    }
  }

  /// Get segment emoji
  String get emoji {
    switch (rewardType.toLowerCase()) {
      case 'coins':
      case 'currency':
        return '🪙';
      case 'gems':
      case 'premium':
        return '💎';
      case 'rare':
        return '✨';
      case 'legendary':
        return '🌟';
      case 'jackpot':
        return '🎉';
      case 'lives':
      case 'health':
        return '❤️';
      case 'powerup':
      case 'boost':
        return '⚡';
      default:
        return '🎁';
    }
  }

  /// Get formatted reward amount
  String get formattedReward {
    if (reward >= 1000000) {
      return '${(reward / 1000000).toStringAsFixed(1)}M';
    } else if (reward >= 1000) {
      return '${(reward / 1000).toStringAsFixed(1)}K';
    }
    return reward.toString();
  }

  /// Get unlock requirement text
  String? get unlockRequirementText {
    if (!isExclusive) return null;

    final requirements = <String>[];
    if (requiredStreak > 0) {
      requirements.add('${requiredStreak}+ streak');
    }
    if (requiredCurrency > 0) {
      requirements.add('${requiredCurrency}💎');
    }

    return requirements.isEmpty ? null : requirements.join(' & ');
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'rewardType': rewardType,
    'reward': reward,
    'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
    'imagePath': imagePath,
    'isExclusive': isExclusive,
    'requiredStreak': requiredStreak,
    'requiredCurrency': requiredCurrency,
    'description': description,
    'probability': probability,
    'metadata': metadata,
    'isEnabled': isEnabled,
    'enabledUntil': enabledUntil?.toIso8601String(),
  };

  /// Create from JSON with validation
  factory WheelSegment.fromJson(Map<String, dynamic> json) {
    try {
      return WheelSegment(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        rewardType: json['rewardType'] ?? 'unknown',
        color: _parseColor(json['color']),
        imagePath: json['imagePath'],
        reward: json['reward'] ?? 0,
        isExclusive: json['isExclusive'] ?? false,
        requiredStreak: json['requiredStreak'] ?? 0,
        requiredCurrency: json['requiredCurrency'] ?? 0,
        description: json['description'],
        probability: (json['probability'] ?? 1.0).toDouble(),
        metadata: json['metadata'] as Map<String, dynamic>?,
        isEnabled: json['isEnabled'] ?? true,
        enabledUntil: json['enabledUntil'] != null
            ? DateTime.parse(json['enabledUntil'])
            : null,
      );
    } catch (e) {
      throw FormatException('Invalid WheelSegment JSON: $e');
    }
  }

  /// Parse color from various formats
  static Color _parseColor(dynamic colorValue) {
    if (colorValue is int) {
      return Color(colorValue);
    } else if (colorValue is String) {
      String hex = colorValue.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if missing
      }
      return Color(int.parse(hex, radix: 16));
    } else {
      return Colors.grey; // Fallback color
    }
  }

  /// Encode list to JSON string
  static String encodeList(List<WheelSegment> segments) {
    try {
      return json.encode(segments.map((e) => e.toJson()).toList());
    } catch (e) {
      throw FormatException('Failed to encode WheelSegment list: $e');
    }
  }

  /// Decode JSON string to list
  static List<WheelSegment> decodeList(String raw) {
    try {
      final List decoded = json.decode(raw);
      return decoded.map((e) => WheelSegment.fromJson(e)).toList();
    } catch (e) {
      throw FormatException('Failed to decode WheelSegment list: $e');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WheelSegment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WheelSegment(id: $id, label: $label, reward: $reward)';
}

/// Enum for segment rarity levels
enum SegmentRarity {
  common,
  uncommon,
  rare,
  legendary;

  /// Get rarity color
  Color get color {
    switch (this) {
      case SegmentRarity.common:
        return Colors.grey;
      case SegmentRarity.uncommon:
        return Colors.green;
      case SegmentRarity.rare:
        return Colors.blue;
      case SegmentRarity.legendary:
        return Colors.purple;
    }
  }

  /// Get rarity display name
  String get displayName {
    switch (this) {
      case SegmentRarity.common:
        return 'Common';
      case SegmentRarity.uncommon:
        return 'Uncommon';
      case SegmentRarity.rare:
        return 'Rare';
      case SegmentRarity.legendary:
        return 'Legendary';
    }
  }
}