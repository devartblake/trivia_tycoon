import 'package:flutter/material.dart';

/// Resolves a backend icon name string to a Flutter IconData.
IconData resolveIcon(String? name, {IconData fallback = Icons.store}) {
  switch (name) {
    case 'store':
      return Icons.store;
    case 'local_offer':
      return Icons.local_offer;
    case 'card_giftcard':
      return Icons.card_giftcard;
    case 'workspace_premium':
      return Icons.workspace_premium;
    case 'star':
      return Icons.star;
    case 'monetization_on':
      return Icons.monetization_on;
    case 'flash_on':
      return Icons.flash_on;
    case 'trending_up':
      return Icons.trending_up;
    case 'diamond':
      return Icons.diamond;
    case 'emoji_events':
      return Icons.emoji_events;
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'storefront':
      return Icons.storefront;
    case 'favorite':
      return Icons.favorite;
    case 'auto_fix_high':
      return Icons.auto_fix_high;
    case 'bolt':
      return Icons.bolt;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'today':
      return Icons.today;
    default:
      return fallback;
  }
}

/// Parses a hex color string (e.g. '#EF4444' or 'EF4444') to a [Color].
Color _hexColor(String hex) {
  final clean = hex.startsWith('#') ? hex.substring(1) : hex;
  return Color(int.parse(clean.padLeft(8, 'F'), radix: 16) | 0xFF000000);
}

/// Parses a list of hex color strings to a [LinearGradient].
LinearGradient resolveGradient(
  List<dynamic>? colors, {
  List<Color> fallback = const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
}) {
  if (colors != null && colors.length >= 2) {
    try {
      return LinearGradient(
        colors: colors.map((c) => _hexColor(c.toString())).toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } catch (_) {}
  }
  return LinearGradient(
    colors: fallback,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ---------------------------------------------------------------------------
// Store Hub
// ---------------------------------------------------------------------------

class StoreSectionData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final String itemCount;
  final String? badge;
  final String preview;

  const StoreSectionData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.itemCount,
    this.badge,
    required this.preview,
  });

  factory StoreSectionData.fromJson(Map<String, dynamic> json) {
    return StoreSectionData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: resolveIcon(json['icon'] as String?),
      gradient: resolveGradient(json['gradient'] as List?),
      route: json['route'] as String? ?? '/store',
      itemCount: json['itemCount'] as String? ?? '',
      badge: json['badge'] as String?,
      preview: json['preview'] as String? ?? '',
    );
  }
}

class FeaturedItemData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String? buttonText;
  final String? sku;
  final DateTime? expiresAt;

  const FeaturedItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.buttonText,
    this.sku,
    this.expiresAt,
  });

  String get countdownLabel {
    if (expiresAt == null) return '';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.inDays > 1) return '${diff.inDays} days left';
    if (diff.inHours > 1) return '${diff.inHours} hours left';
    return 'Ending soon';
  }

  factory FeaturedItemData.fromJson(Map<String, dynamic> json) {
    return FeaturedItemData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: resolveIcon(json['icon'] as String?, fallback: Icons.auto_awesome),
      gradient: resolveGradient(
        json['gradient'] as List?,
        fallback: const [Color(0xFF10B981), Color(0xFF059669)],
      ),
      buttonText: json['buttonText'] as String?,
      sku: json['sku'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }
}

class StoreHubStats {
  final String totalItems;
  final String activeOffers;
  final String newToday;

  const StoreHubStats({
    required this.totalItems,
    required this.activeOffers,
    required this.newToday,
  });

  factory StoreHubStats.fromJson(Map<String, dynamic> json) {
    return StoreHubStats(
      totalItems: json['totalItems']?.toString() ?? '0',
      activeOffers: json['activeOffers']?.toString() ?? '0',
      newToday: json['newToday']?.toString() ?? '0',
    );
  }
}

class StoreHubData {
  final List<StoreSectionData> sections;
  final FeaturedItemData? featured;
  final StoreHubStats stats;
  final String? flashSaleMessage;

  const StoreHubData({
    required this.sections,
    this.featured,
    required this.stats,
    this.flashSaleMessage,
  });

  factory StoreHubData.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List? ?? [];
    final rawFeatured = json['featured'] as Map<String, dynamic>?;
    final rawStats = json['stats'] as Map<String, dynamic>? ?? {};

    return StoreHubData(
      sections: rawSections
          .whereType<Map>()
          .map((s) => StoreSectionData.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      featured:
          rawFeatured != null ? FeaturedItemData.fromJson(rawFeatured) : null,
      stats: StoreHubStats.fromJson(rawStats),
      flashSaleMessage: json['flashSaleMessage'] as String?,
    );
  }

  // Hardcoded fallback so the UI works before the backend endpoint exists.
  static StoreHubData get fallback => StoreHubData(
        sections: [
          const StoreSectionData(
            id: 'game-store',
            title: 'Game Store',
            subtitle: 'Power-ups, themes & more',
            icon: Icons.store,
            gradient:
                LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            route: '/store',
            itemCount: '50+ items',
            badge: null,
            preview: 'Latest power-ups and themes available',
          ),
          const StoreSectionData(
            id: 'daily-items',
            title: 'Daily Items',
            subtitle: 'Restocks every day at midnight UTC',
            icon: Icons.today,
            gradient:
                LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            route: '/store/daily',
            itemCount: '4 items today',
            badge: 'NEW',
            preview: 'Fresh power-ups and cosmetics, every day',
          ),
          const StoreSectionData(
            id: 'special-offers',
            title: 'Special Offers',
            subtitle: 'Limited time deals',
            icon: Icons.local_offer,
            gradient:
                LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
            route: '/store-special',
            itemCount: '8 deals',
            badge: 'HOT',
            preview: 'Flash sales and exclusive bundles',
          ),
          const StoreSectionData(
            id: 'gifts-center',
            title: 'Gifts Center',
            subtitle: 'Send & receive gifts',
            icon: Icons.card_giftcard,
            gradient:
                LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
            route: '/gifts',
            itemCount: '3 pending',
            badge: null,
            preview: 'Energy packs and coin gifts',
          ),
          const StoreSectionData(
            id: 'premium-store',
            title: 'Premium Store',
            subtitle: 'Exclusive content',
            icon: Icons.workspace_premium,
            gradient:
                LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            route: '/store-premium',
            itemCount: 'VIP only',
            badge: null,
            preview: '3D avatars and ad-free experience',
          ),
        ],
        featured: FeaturedItemData(
          id: 'weekly-bundle',
          title: 'Weekly Power-up Bundle',
          subtitle: '5 premium power-ups for the price of 2',
          icon: Icons.auto_awesome,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          buttonText: 'Get Bundle',
          expiresAt: DateTime.now().add(const Duration(days: 2)),
        ),
        stats: const StoreHubStats(
          totalItems: '156',
          activeOffers: '8',
          newToday: '12',
        ),
        flashSaleMessage: 'Flash Sale: Up to 70% off premium items!',
      );
}
