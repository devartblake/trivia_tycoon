import 'package:flutter/material.dart';
import 'store_hub_model.dart';

class OfferItem {
  final String id;
  final String tab;
  final String title;
  final String description;
  final String price;
  final String? originalPrice;
  final int? discount;
  final IconData icon;
  final LinearGradient gradient;
  final String buttonText;
  final bool isPopular;
  final String? tier;
  final String? billingPeriod;

  const OfferItem({
    required this.id,
    required this.tab,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.icon,
    required this.gradient,
    required this.buttonText,
    this.isPopular = false,
    this.tier,
    this.billingPeriod,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) {
    return OfferItem(
      id: json['id'] as String? ?? '',
      tab: json['tab'] as String? ?? 'Limited Time',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price']?.toString() ?? '0.00',
      originalPrice: json['originalPrice']?.toString(),
      discount: json['discount'] as int?,
      icon: resolveIcon(json['icon'] as String?, fallback: Icons.local_offer),
      gradient: resolveGradient(json['gradient'] as List?),
      buttonText: json['buttonText'] as String? ?? 'Buy Now',
      isPopular: json['isPopular'] as bool? ?? false,
      tier: json['tier'] as String?,
      billingPeriod: json['billingPeriod'] as String?,
    );
  }
}

class FeaturedOffer {
  final String badgeText;
  final String headline;
  final String subtitle;
  final String description;
  final DateTime? expiresAt;
  final String buttonText;
  final String? sku;

  const FeaturedOffer({
    required this.badgeText,
    required this.headline,
    required this.subtitle,
    required this.description,
    this.expiresAt,
    required this.buttonText,
    this.sku,
  });

  String get countdownLabel {
    if (expiresAt == null) return '';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 1) return '${diff.inDays} days left';
    if (diff.inHours > 1) return '${diff.inHours}h left';
    if (diff.inMinutes > 1) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }

  factory FeaturedOffer.fromJson(Map<String, dynamic> json) {
    return FeaturedOffer(
      badgeText: json['badgeText'] as String? ?? 'SALE',
      headline: json['headline'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      buttonText: json['buttonText'] as String? ?? 'Claim Offer',
      sku: json['sku'] as String?,
    );
  }
}

class StoreOffersData {
  final FeaturedOffer? featured;
  final List<String> tabs;
  final List<OfferItem> offers;

  const StoreOffersData({
    this.featured,
    required this.tabs,
    required this.offers,
  });

  List<OfferItem> offersForTab(String tab) =>
      offers.where((o) => o.tab == tab).toList();

  factory StoreOffersData.fromJson(Map<String, dynamic> json) {
    final rawFeatured = json['featured'] as Map<String, dynamic>?;
    final rawTabs = (json['tabs'] as List?)?.map((e) => e.toString()).toList();
    final rawOffers = json['offers'] as List? ?? [];

    return StoreOffersData(
      featured:
          rawFeatured != null ? FeaturedOffer.fromJson(rawFeatured) : null,
      tabs: rawTabs ??
          const ['Limited Time', 'Daily Deals', 'Premium', 'Bundles'],
      offers: rawOffers
          .whereType<Map>()
          .map((o) => OfferItem.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
    );
  }

  static StoreOffersData get fallback => StoreOffersData(
        featured: FeaturedOffer(
          badgeText: 'FLASH SALE',
          headline: '80% OFF',
          subtitle: 'Premium Membership',
          description: 'Limited time offer ends soon!',
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          buttonText: 'Claim Offer',
        ),
        tabs: const ['Limited Time', 'Daily Deals', 'Premium', 'Bundles'],
        offers: const [
          OfferItem(
            id: 'premium-upgrade',
            tab: 'Limited Time',
            title: 'Premium Upgrade',
            description:
                'Unlock unlimited lives, double XP, and exclusive content',
            price: '4.99',
            originalPrice: '24.99',
            discount: 80,
            icon: Icons.star,
            gradient:
                LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
            buttonText: 'Upgrade Now',
            isPopular: true,
          ),
          OfferItem(
            id: 'mega-coin-pack',
            tab: 'Limited Time',
            title: 'Mega Coin Pack',
            description: '50,000 coins + 1,000 bonus coins',
            price: '9.99',
            originalPrice: '19.99',
            discount: 50,
            icon: Icons.monetization_on,
            gradient:
                LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            buttonText: 'Buy Coins',
          ),
          OfferItem(
            id: 'energy-refill',
            tab: 'Daily Deals',
            title: 'Energy Refill Bundle',
            description: '10 full energy refills for today only',
            price: '2.99',
            icon: Icons.flash_on,
            gradient:
                LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            buttonText: 'Get Energy',
          ),
          OfferItem(
            id: 'double-xp',
            tab: 'Daily Deals',
            title: 'Double XP Boost',
            description: '24-hour double XP multiplier',
            price: '1.99',
            icon: Icons.trending_up,
            gradient:
                LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
            buttonText: 'Activate Boost',
          ),
          OfferItem(
            id: 'monthly-premium',
            tab: 'Premium',
            title: 'Monthly Premium',
            description: 'All premium features for 30 days',
            price: '9.99',
            icon: Icons.workspace_premium,
            gradient:
                LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            buttonText: 'Subscribe',
            isPopular: true,
            tier: 'premium',
            billingPeriod: 'monthly',
          ),
          OfferItem(
            id: 'elite-season-pass',
            tab: 'Premium',
            title: 'Elite Season Pass',
            description: 'Best value seasonal plan with the highest tier perks',
            price: '39.99',
            originalPrice: '119.88',
            discount: 67,
            icon: Icons.diamond,
            gradient:
                LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
            buttonText: 'Best Deal',
            tier: 'elite',
            billingPeriod: 'seasonal',
          ),
          OfferItem(
            id: 'starter-pack',
            tab: 'Bundles',
            title: 'Starter Pack',
            description: '10,000 coins + 5 lives + 3 power-ups',
            price: '4.99',
            icon: Icons.card_giftcard,
            gradient:
                LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
            buttonText: 'Get Bundle',
          ),
          OfferItem(
            id: 'champion-bundle',
            tab: 'Bundles',
            title: 'Champion Bundle',
            description: 'Premium + 50k coins + exclusive avatar',
            price: '19.99',
            originalPrice: '34.97',
            discount: 43,
            icon: Icons.emoji_events,
            gradient:
                LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            buttonText: 'Become Champion',
            isPopular: true,
          ),
        ],
      );
}
