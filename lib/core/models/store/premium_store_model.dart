import 'package:flutter/material.dart';
import 'store_hub_model.dart';
import 'store_gift_model.dart';

// ---------------------------------------------------------------------------
// Ad-Remove Plans
// ---------------------------------------------------------------------------

class AdRemovePlan {
  final String id;
  final String durationLabel;
  final String price;
  final String badge;
  final Color accentColor;
  final bool isBestValue;
  final String title;
  final String subtitle;
  final String sku;

  const AdRemovePlan({
    required this.id,
    required this.durationLabel,
    required this.price,
    required this.badge,
    required this.accentColor,
    required this.isBestValue,
    this.title = '',
    this.subtitle = '',
    this.sku = '',
  });

  factory AdRemovePlan.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final subtitle = json['subtitle'] as String? ?? '';
    final price = json['price'] as String? ??
        json['priceLabel'] as String? ??
        '';
    final durationLabel = json['durationLabel'] as String? ??
        title;

    return AdRemovePlan(
      id: json['id'] as String? ?? '',
      durationLabel: durationLabel,
      price: price,
      badge: json['badge'] as String? ?? '',
      accentColor: resolveColor(json['accentColor'] as String?),
      isBestValue: json['isBestValue'] as bool? ?? false,
      title: title,
      subtitle: subtitle,
      sku: json['sku'] as String? ?? '',
    );
  }

  String get displayTitle => title.isNotEmpty ? title : durationLabel;

  String get displaySubtitle => subtitle;

  String? get tier {
    final normalized = '${id.toLowerCase()} ${sku.toLowerCase()}';
    if (normalized.contains('elite')) return 'elite';
    if (normalized.contains('premium')) return 'premium';
    return null;
  }

  String? get billingPeriod {
    final normalized = '${id.toLowerCase()} ${sku.toLowerCase()}';
    if (normalized.contains('seasonal') || normalized.contains('season')) {
      return 'seasonal';
    }
    if (normalized.contains('monthly') || normalized.contains('month')) {
      return 'monthly';
    }
    return null;
  }
}

class AdFreeConfig {
  final List<AdRemovePlan> plans;
  final List<String> benefits;
  final String title;
  final String subtitle;

  const AdFreeConfig({
    required this.plans,
    required this.benefits,
    this.title = '',
    this.subtitle = '',
  });

  factory AdFreeConfig.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'] as List? ?? [];
    final rawBenefits = json['benefits'] as List? ?? [];
    return AdFreeConfig(
      plans: rawPlans
          .whereType<Map>()
          .map((p) => AdRemovePlan.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      benefits: rawBenefits.map((b) => b.toString()).toList(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }

  AdRemovePlan? get defaultPurchasePlan {
    if (plans.isEmpty) return null;
    for (final plan in plans) {
      if (plan.isBestValue) return plan;
    }
    return plans.first;
  }

  static const AdFreeConfig fallback = AdFreeConfig(
    plans: [
      AdRemovePlan(
        id: 'ad-free-365',
        durationLabel: '365 DAYS',
        price: r'$5.99',
        badge: 'Best Value - Save 70%',
        accentColor: Color(0xFF10B981),
        isBestValue: true,
      ),
      AdRemovePlan(
        id: 'ad-free-28',
        durationLabel: '28 DAYS',
        price: r'$3.99',
        badge: 'Popular Choice',
        accentColor: Color(0xFF6366F1),
        isBestValue: false,
      ),
      AdRemovePlan(
        id: 'ad-free-7',
        durationLabel: '7 DAYS',
        price: r'$1.99',
        badge: 'Trial Period',
        accentColor: Color(0xFF8B5CF6),
        isBestValue: false,
      ),
    ],
    benefits: [
      'Uninterrupted gameplay',
      'Faster loading times',
      'Less battery usage',
      'Premium experience',
    ],
  );
}

// ---------------------------------------------------------------------------
// Sale Info
// ---------------------------------------------------------------------------

class SaleBenefitItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const SaleBenefitItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  factory SaleBenefitItem.fromJson(Map<String, dynamic> json) => SaleBenefitItem(
        icon: resolveIcon(json['icon'] as String?, fallback: Icons.star),
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        color: resolveColor(json['color'] as String?),
      );
}

class SaleInfoData {
  final String badgeText;
  final String discount;
  final String originalPrice;
  final String salePrice;
  final List<SaleBenefitItem> benefits;
  final DateTime? expiresAt;
  final String buttonText;
  final String? sku;
  final String? tier;
  final String? billingPeriod;

  const SaleInfoData({
    required this.badgeText,
    required this.discount,
    required this.originalPrice,
    required this.salePrice,
    required this.benefits,
    this.expiresAt,
    this.buttonText = 'Claim This Deal',
    this.sku,
    this.tier,
    this.billingPeriod,
  });

  factory SaleInfoData.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'] as List? ?? [];
    return SaleInfoData(
      badgeText: json['badgeText'] as String? ?? 'FLASH SALE',
      discount: json['discount'] as String? ?? '',
      originalPrice: json['originalPrice'] as String? ?? '',
      salePrice: json['salePrice'] as String? ?? '',
      benefits: rawBenefits
          .whereType<Map>()
          .map((b) => SaleBenefitItem.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      buttonText: json['buttonText'] as String? ?? 'Claim This Deal',
      sku: json['sku'] as String?,
      tier: json['tier'] as String?,
      billingPeriod: json['billingPeriod'] as String?,
    );
  }

  static const SaleInfoData fallback = SaleInfoData(
    badgeText: 'FLASH SALE',
    discount: '80% OFF',
    originalPrice: r'$10',
    salePrice: r'$1.99',
    benefits: [
      SaleBenefitItem(
        icon: Icons.verified,
        value: '5',
        label: 'Premium\nFeatures',
        color: Color(0xFF10B981),
      ),
      SaleBenefitItem(
        icon: Icons.monetization_on,
        value: '3400',
        label: 'Bonus\nCoins',
        color: Color(0xFFF59E0B),
      ),
      SaleBenefitItem(
        icon: Icons.confirmation_number,
        value: '400',
        label: 'Special\nTickets',
        color: Color(0xFF8B5CF6),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Reward Center
// ---------------------------------------------------------------------------

class RewardCard {
  final String id;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final String reward;
  final double? progress;
  final bool isAvailable;

  const RewardCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.reward,
    this.progress,
    required this.isAvailable,
  });

  factory RewardCard.fromJson(Map<String, dynamic> json) => RewardCard(
        id: json['id'] as String? ?? json['rewardId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        gradient: json['gradient'] is List
            ? resolveGradient(json['gradient'] as List?)
            : resolveGradient(
                [
                  json['gradientStart'] ?? '#6366F1',
                  json['gradientEnd'] ?? '#8B5CF6',
                ],
              ),
        reward: json['reward'] as String? ??
            json['rewardLabel'] as String? ??
            '',
        progress: (json['progress'] as num?)?.toDouble(),
        isAvailable: json['isAvailable'] as bool? ??
            json['isClaimAvailable'] as bool? ??
            false,
      );
}

class RewardCenterData {
  final List<RewardCard> cards;
  final int completedCount;
  final int totalCount;

  const RewardCenterData({
    required this.cards,
    required this.completedCount,
    required this.totalCount,
  });

  factory RewardCenterData.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'] as List? ?? [];
    final cards = rawCards
        .whereType<Map>()
        .map((c) => RewardCard.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final completedCount = json['completedCount'] as int? ??
        cards.where((card) => !card.isAvailable).length;
    final totalCount = json['totalCount'] as int? ?? cards.length;

    return RewardCenterData(
      cards: cards,
      completedCount: completedCount,
      totalCount: totalCount,
    );
  }

  static const RewardCenterData fallback = RewardCenterData(
    cards: [
      RewardCard(
        id: 'daily-checkin',
        title: 'Daily Check-in',
        subtitle: 'Day 3 of 7',
        gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        reward: '500 Coins',
        progress: 0.43,
        isAvailable: true,
      ),
      RewardCard(
        id: 'watch-ad',
        title: 'Watch Ad',
        subtitle: '2 available today',
        gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        reward: '200 Coins',
        progress: null,
        isAvailable: true,
      ),
    ],
    completedCount: 1,
    totalCount: 2,
  );
}

// ---------------------------------------------------------------------------
// Premium Store (aggregate)
// ---------------------------------------------------------------------------

class PremiumStoreData {
  final AdFreeConfig adFree;
  final SaleInfoData? saleInfo;
  final RewardCenterData rewardCenter;

  const PremiumStoreData({
    required this.adFree,
    this.saleInfo,
    required this.rewardCenter,
  });

  factory PremiumStoreData.fromJson(Map<String, dynamic> json) {
    final rawAdFree = json['adFree'] as Map<String, dynamic>?;
    final rawSaleInfo = json['saleInfo'] as Map<String, dynamic>?;
    final rawReward = json['rewardCenter'] as Map<String, dynamic>?;
    return PremiumStoreData(
      adFree: rawAdFree != null ? AdFreeConfig.fromJson(rawAdFree) : AdFreeConfig.fallback,
      saleInfo: rawSaleInfo != null ? SaleInfoData.fromJson(rawSaleInfo) : null,
      rewardCenter: rawReward != null ? RewardCenterData.fromJson(rawReward) : RewardCenterData.fallback,
    );
  }

  static PremiumStoreData get fallback => const PremiumStoreData(
        adFree: AdFreeConfig.fallback,
        saleInfo: SaleInfoData.fallback,
        rewardCenter: RewardCenterData.fallback,
      );
}
