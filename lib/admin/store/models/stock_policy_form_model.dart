/// Editable stock policy for a catalog SKU.
/// Maps to PUT /admin/store/policies/{sku} request body.
class StockPolicyFormModel {
  final String sku;
  final String itemTitle;
  final String itemType;
  final String policyType; // unlimited | per_user | one_time_purchase | time_limited | event_limited
  final int? maxQuantity;
  final String? resetInterval; // hourly | daily | weekly | seasonal | none
  final bool isOneTimePurchase;
  final bool isUnlimited;
  final DateTime? expiresAt;
  final bool requiresPremium;
  final int? minimumLevel;
  final bool isVisible;
  final bool isPurchasable;

  const StockPolicyFormModel({
    required this.sku,
    required this.itemTitle,
    required this.itemType,
    this.policyType = 'unlimited',
    this.maxQuantity,
    this.resetInterval,
    this.isOneTimePurchase = false,
    this.isUnlimited = true,
    this.expiresAt,
    this.requiresPremium = false,
    this.minimumLevel,
    this.isVisible = true,
    this.isPurchasable = true,
  });

  StockPolicyFormModel copyWith({
    String? sku,
    String? itemTitle,
    String? itemType,
    String? policyType,
    int? maxQuantity,
    String? resetInterval,
    bool? isOneTimePurchase,
    bool? isUnlimited,
    DateTime? expiresAt,
    bool? requiresPremium,
    int? minimumLevel,
    bool? isVisible,
    bool? isPurchasable,
    bool clearMaxQuantity = false,
    bool clearResetInterval = false,
    bool clearExpiresAt = false,
    bool clearMinimumLevel = false,
  }) {
    return StockPolicyFormModel(
      sku: sku ?? this.sku,
      itemTitle: itemTitle ?? this.itemTitle,
      itemType: itemType ?? this.itemType,
      policyType: policyType ?? this.policyType,
      maxQuantity: clearMaxQuantity ? null : (maxQuantity ?? this.maxQuantity),
      resetInterval: clearResetInterval ? null : (resetInterval ?? this.resetInterval),
      isOneTimePurchase: isOneTimePurchase ?? this.isOneTimePurchase,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      requiresPremium: requiresPremium ?? this.requiresPremium,
      minimumLevel: clearMinimumLevel ? null : (minimumLevel ?? this.minimumLevel),
      isVisible: isVisible ?? this.isVisible,
      isPurchasable: isPurchasable ?? this.isPurchasable,
    );
  }

  factory StockPolicyFormModel.fromJson(Map<String, dynamic> json) {
    return StockPolicyFormModel(
      sku: (json['sku'] ?? '').toString(),
      itemTitle: (json['itemTitle'] ?? json['name'] ?? '').toString(),
      itemType: (json['itemType'] ?? json['type'] ?? '').toString(),
      policyType: (json['policyType'] ?? 'unlimited').toString(),
      maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
      resetInterval: json['resetInterval']?.toString(),
      isOneTimePurchase: json['isOneTimePurchase'] as bool? ?? false,
      isUnlimited: json['isUnlimited'] as bool? ?? true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      requiresPremium: json['requiresPremium'] as bool? ?? false,
      minimumLevel: (json['minimumLevel'] as num?)?.toInt(),
      isVisible: json['isVisible'] as bool? ?? true,
      isPurchasable: json['isPurchasable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'policyType': policyType,
        'maxQuantity': maxQuantity,
        'resetInterval': resetInterval,
        'isOneTimePurchase': isOneTimePurchase,
        'isUnlimited': isUnlimited,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'requiresPremium': requiresPremium,
        'minimumLevel': minimumLevel,
        'isVisible': isVisible,
        'isPurchasable': isPurchasable,
      };

  /// Validation — returns error string or null.
  String? validate() {
    if (isUnlimited && maxQuantity != null) {
      return 'Unlimited items cannot have a max quantity.';
    }
    if (isOneTimePurchase && (maxQuantity != null && maxQuantity! > 1)) {
      return 'One-time purchase items are limited to quantity 1.';
    }
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc())) {
      return 'Expiry date must be in the future.';
    }
    return null;
  }
}

/// Reward limit config for a specific reward SKU.
/// Maps to PUT /admin/store/reward-limits/{rewardId}.
class RewardLimitFormModel {
  final String rewardId;
  final int maxClaimsPerInterval;
  final String interval; // hourly | daily | weekly | none
  final int coinPayout;
  final bool requiresAd;
  final int? requiredStreak;
  final bool isActive;

  const RewardLimitFormModel({
    required this.rewardId,
    this.maxClaimsPerInterval = 1,
    this.interval = 'daily',
    this.coinPayout = 0,
    this.requiresAd = false,
    this.requiredStreak,
    this.isActive = true,
  });

  RewardLimitFormModel copyWith({
    String? rewardId,
    int? maxClaimsPerInterval,
    String? interval,
    int? coinPayout,
    bool? requiresAd,
    int? requiredStreak,
    bool? isActive,
    bool clearStreak = false,
  }) {
    return RewardLimitFormModel(
      rewardId: rewardId ?? this.rewardId,
      maxClaimsPerInterval: maxClaimsPerInterval ?? this.maxClaimsPerInterval,
      interval: interval ?? this.interval,
      coinPayout: coinPayout ?? this.coinPayout,
      requiresAd: requiresAd ?? this.requiresAd,
      requiredStreak: clearStreak ? null : (requiredStreak ?? this.requiredStreak),
      isActive: isActive ?? this.isActive,
    );
  }

  factory RewardLimitFormModel.fromJson(Map<String, dynamic> json) {
    return RewardLimitFormModel(
      rewardId: (json['rewardId'] ?? json['id'] ?? '').toString(),
      maxClaimsPerInterval: (json['maxClaimsPerInterval'] as num?)?.toInt() ?? 1,
      interval: (json['interval'] ?? 'daily').toString(),
      coinPayout: (json['coinPayout'] as num?)?.toInt() ?? 0,
      requiresAd: json['requiresAd'] as bool? ?? false,
      requiredStreak: (json['requiredStreak'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'maxClaimsPerInterval': maxClaimsPerInterval,
        'interval': interval,
        'coinPayout': coinPayout,
        'requiresAd': requiresAd,
        'requiredStreak': requiredStreak,
        'isActive': isActive,
      };
}
