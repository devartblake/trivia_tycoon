import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/store/store_hub_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // resolveIcon
  // -------------------------------------------------------------------------

  group('resolveIcon', () {
    test('store → Icons.store', () {
      expect(resolveIcon('store'), Icons.store);
    });

    test('local_offer → Icons.local_offer', () {
      expect(resolveIcon('local_offer'), Icons.local_offer);
    });

    test('card_giftcard → Icons.card_giftcard', () {
      expect(resolveIcon('card_giftcard'), Icons.card_giftcard);
    });

    test('workspace_premium → Icons.workspace_premium', () {
      expect(resolveIcon('workspace_premium'), Icons.workspace_premium);
    });

    test('star → Icons.star', () {
      expect(resolveIcon('star'), Icons.star);
    });

    test('monetization_on → Icons.monetization_on', () {
      expect(resolveIcon('monetization_on'), Icons.monetization_on);
    });

    test('flash_on → Icons.flash_on', () {
      expect(resolveIcon('flash_on'), Icons.flash_on);
    });

    test('trending_up → Icons.trending_up', () {
      expect(resolveIcon('trending_up'), Icons.trending_up);
    });

    test('diamond → Icons.diamond', () {
      expect(resolveIcon('diamond'), Icons.diamond);
    });

    test('emoji_events → Icons.emoji_events', () {
      expect(resolveIcon('emoji_events'), Icons.emoji_events);
    });

    test('auto_awesome → Icons.auto_awesome', () {
      expect(resolveIcon('auto_awesome'), Icons.auto_awesome);
    });

    test('storefront → Icons.storefront', () {
      expect(resolveIcon('storefront'), Icons.storefront);
    });

    test('favorite → Icons.favorite', () {
      expect(resolveIcon('favorite'), Icons.favorite);
    });

    test('auto_fix_high → Icons.auto_fix_high', () {
      expect(resolveIcon('auto_fix_high'), Icons.auto_fix_high);
    });

    test('bolt → Icons.bolt', () {
      expect(resolveIcon('bolt'), Icons.bolt);
    });

    test('local_fire_department → Icons.local_fire_department', () {
      expect(resolveIcon('local_fire_department'), Icons.local_fire_department);
    });

    test('today → Icons.today', () {
      expect(resolveIcon('today'), Icons.today);
    });

    test('unknown name → returns fallback (default: Icons.store)', () {
      expect(resolveIcon('unknown_icon'), Icons.store);
    });

    test('null → returns fallback', () {
      expect(resolveIcon(null), Icons.store);
    });

    test('custom fallback returned for unknown name', () {
      expect(
        resolveIcon('no_such_icon', fallback: Icons.help),
        Icons.help,
      );
    });
  });

  // -------------------------------------------------------------------------
  // resolveGradient
  // -------------------------------------------------------------------------

  group('resolveGradient', () {
    test('returns gradient from 2 hex colors (with #)', () {
      final g = resolveGradient(['#FF0000', '#0000FF']);
      expect(g.colors.length, 2);
      expect(g.colors.first, const Color(0xFFFF0000));
      expect(g.colors.last, const Color(0xFF0000FF));
    });

    test('returns gradient from hex colors without #', () {
      final g = resolveGradient(['FF0000', '00FF00']);
      expect(g.colors.first, const Color(0xFFFF0000));
    });

    test('returns gradient from 3+ colors', () {
      final g = resolveGradient(['#FF0000', '#00FF00', '#0000FF']);
      expect(g.colors.length, 3);
    });

    test('returns fallback when list is null', () {
      final g = resolveGradient(null);
      expect(g.colors.length, 2);
      expect(g.colors.first, const Color(0xFF6366F1));
      expect(g.colors.last, const Color(0xFF8B5CF6));
    });

    test('returns fallback when list has fewer than 2 colors', () {
      final g = resolveGradient(['#FF0000']);
      expect(g.colors.first, const Color(0xFF6366F1));
    });

    test('returns fallback when list is empty', () {
      final g = resolveGradient([]);
      expect(g.colors.first, const Color(0xFF6366F1));
    });

    test('custom fallback used when list is null', () {
      final g = resolveGradient(
        null,
        fallback: const [Color(0xFFAABBCC), Color(0xFFDDEEFF)],
      );
      expect(g.colors.first, const Color(0xFFAABBCC));
    });

    test('gradient alignment is topLeft → bottomRight', () {
      final g = resolveGradient(['#FF0000', '#0000FF']);
      expect(g.begin, Alignment.topLeft);
      expect(g.end, Alignment.bottomRight);
    });
  });

  // -------------------------------------------------------------------------
  // StoreSectionData.fromJson
  // -------------------------------------------------------------------------

  group('StoreSectionData.fromJson', () {
    Map<String, dynamic> sectionJson({
      String id = 'sec1',
      String title = 'Power-Ups',
      String subtitle = 'Boost your score',
      String icon = 'flash_on',
      List<dynamic>? gradient,
      String? route,
      String itemCount = '10 items',
      String? badge,
      String preview = 'Great power-ups',
    }) =>
        {
          'id': id,
          'title': title,
          'subtitle': subtitle,
          'icon': icon,
          if (gradient != null) 'gradient': gradient,
          if (route != null) 'route': route,
          'itemCount': itemCount,
          if (badge != null) 'badge': badge,
          'preview': preview,
        };

    test('parses id', () {
      expect(StoreSectionData.fromJson(sectionJson(id: 'powerups')).id,
          'powerups');
    });

    test('parses title', () {
      expect(
          StoreSectionData.fromJson(sectionJson(title: 'Gems')).title, 'Gems');
    });

    test('parses subtitle', () {
      expect(
          StoreSectionData.fromJson(sectionJson(subtitle: 'Buy gems')).subtitle,
          'Buy gems');
    });

    test('parses icon', () {
      expect(StoreSectionData.fromJson(sectionJson(icon: 'diamond')).icon,
          Icons.diamond);
    });

    test('icon defaults to Icons.store for unknown name', () {
      expect(StoreSectionData.fromJson(sectionJson(icon: 'unknown')).icon,
          Icons.store);
    });

    test('parses gradient from list', () {
      final s = StoreSectionData.fromJson(
          sectionJson(gradient: ['#FF0000', '#0000FF']));
      expect(s.gradient.colors.first, const Color(0xFFFF0000));
    });

    test('gradient falls back when absent', () {
      final s = StoreSectionData.fromJson(sectionJson());
      expect(s.gradient.colors.length, 2);
    });

    test('parses route', () {
      final s =
          StoreSectionData.fromJson(sectionJson(route: '/store/powerups'));
      expect(s.route, '/store/powerups');
    });

    test('route defaults to /store when absent', () {
      final s = StoreSectionData.fromJson(sectionJson());
      expect(s.route, '/store');
    });

    test('parses itemCount', () {
      expect(
          StoreSectionData.fromJson(sectionJson(itemCount: '5 items'))
              .itemCount,
          '5 items');
    });

    test('parses badge', () {
      expect(StoreSectionData.fromJson(sectionJson(badge: 'HOT')).badge, 'HOT');
    });

    test('badge is null when absent', () {
      expect(StoreSectionData.fromJson(sectionJson()).badge, isNull);
    });

    test('parses preview', () {
      expect(
          StoreSectionData.fromJson(sectionJson(preview: 'Best power-ups'))
              .preview,
          'Best power-ups');
    });

    test('id defaults to "" when absent', () {
      final json = sectionJson();
      json.remove('id');
      expect(StoreSectionData.fromJson(json).id, '');
    });
  });

  // -------------------------------------------------------------------------
  // FeaturedItemData.fromJson
  // -------------------------------------------------------------------------

  group('FeaturedItemData.fromJson', () {
    Map<String, dynamic> featuredJson({
      String id = 'feat1',
      String title = 'Weekly Bundle',
      String subtitle = '5 power-ups',
      String icon = 'auto_awesome',
      List<dynamic>? gradient,
      String? buttonText,
      String? sku,
      String? expiresAt,
    }) =>
        {
          'id': id,
          'title': title,
          'subtitle': subtitle,
          'icon': icon,
          if (gradient != null) 'gradient': gradient,
          if (buttonText != null) 'buttonText': buttonText,
          if (sku != null) 'sku': sku,
          if (expiresAt != null) 'expiresAt': expiresAt,
        };

    test('parses id', () {
      expect(FeaturedItemData.fromJson(featuredJson(id: 'f99')).id, 'f99');
    });

    test('parses title', () {
      expect(FeaturedItemData.fromJson(featuredJson(title: 'Mega Deal')).title,
          'Mega Deal');
    });

    test('parses subtitle', () {
      expect(
          FeaturedItemData.fromJson(featuredJson(subtitle: 'Great value'))
              .subtitle,
          'Great value');
    });

    test('parses icon', () {
      expect(FeaturedItemData.fromJson(featuredJson(icon: 'star')).icon,
          Icons.star);
    });

    test('icon falls back to auto_awesome for unknown name', () {
      expect(FeaturedItemData.fromJson(featuredJson(icon: 'unk')).icon,
          Icons.auto_awesome);
    });

    test('parses buttonText', () {
      expect(
          FeaturedItemData.fromJson(featuredJson(buttonText: 'Buy Now'))
              .buttonText,
          'Buy Now');
    });

    test('buttonText is null when absent', () {
      expect(FeaturedItemData.fromJson(featuredJson()).buttonText, isNull);
    });

    test('parses sku', () {
      expect(
          FeaturedItemData.fromJson(featuredJson(sku: 'SKU001')).sku, 'SKU001');
    });

    test('sku is null when absent', () {
      expect(FeaturedItemData.fromJson(featuredJson()).sku, isNull);
    });

    test('parses expiresAt', () {
      final f = FeaturedItemData.fromJson(
          featuredJson(expiresAt: '2025-12-31T23:59:00.000Z'));
      expect(f.expiresAt, isNotNull);
      expect(f.expiresAt!.month, 12);
    });

    test('expiresAt is null when absent', () {
      expect(FeaturedItemData.fromJson(featuredJson()).expiresAt, isNull);
    });

    test('invalid expiresAt returns null via tryParse', () {
      final f =
          FeaturedItemData.fromJson(featuredJson(expiresAt: 'not-a-date'));
      expect(f.expiresAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // FeaturedItemData — countdownLabel
  // -------------------------------------------------------------------------

  group('FeaturedItemData — countdownLabel', () {
    FeaturedItemData makeItem({DateTime? expiresAt}) => FeaturedItemData(
          id: 'test',
          title: 'Test',
          subtitle: '',
          icon: Icons.store,
          gradient: const LinearGradient(
              colors: [Color(0xFF000000), Color(0xFFFFFFFF)]),
          expiresAt: expiresAt,
        );

    test('returns "" when expiresAt is null', () {
      expect(makeItem().countdownLabel, '');
    });

    test('returns "N days left" when > 1 day remaining', () {
      final item =
          makeItem(expiresAt: DateTime.now().add(const Duration(days: 5)));
      expect(item.countdownLabel, contains('days left'));
    });

    test('returns "N hours left" when > 1 hour but ≤ 1 day remaining', () {
      final item =
          makeItem(expiresAt: DateTime.now().add(const Duration(hours: 3)));
      expect(item.countdownLabel, contains('hours left'));
    });

    test('returns "Ending soon" when ≤ 1 hour remaining', () {
      final item =
          makeItem(expiresAt: DateTime.now().add(const Duration(minutes: 30)));
      expect(item.countdownLabel, 'Ending soon');
    });

    test('returns "Ending soon" when expiresAt is in the past', () {
      final item = makeItem(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)));
      expect(item.countdownLabel, 'Ending soon');
    });
  });

  // -------------------------------------------------------------------------
  // StoreHubStats.fromJson
  // -------------------------------------------------------------------------

  group('StoreHubStats.fromJson', () {
    test('parses string values', () {
      final stats = StoreHubStats.fromJson({
        'totalItems': '200',
        'activeOffers': '15',
        'newToday': '8',
      });
      expect(stats.totalItems, '200');
      expect(stats.activeOffers, '15');
      expect(stats.newToday, '8');
    });

    test('coerces int values via toString()', () {
      final stats = StoreHubStats.fromJson({
        'totalItems': 200,
        'activeOffers': 15,
        'newToday': 8,
      });
      expect(stats.totalItems, '200');
      expect(stats.activeOffers, '15');
      expect(stats.newToday, '8');
    });

    test('defaults to "0" when keys absent', () {
      final stats = StoreHubStats.fromJson({});
      expect(stats.totalItems, '0');
      expect(stats.activeOffers, '0');
      expect(stats.newToday, '0');
    });
  });

  // -------------------------------------------------------------------------
  // StoreHubData.fromJson — legacy format
  // -------------------------------------------------------------------------

  group('StoreHubData.fromJson — legacy format', () {
    Map<String, dynamic> legacyJson({
      List<dynamic>? sections,
      Map<String, dynamic>? featured,
      Map<String, dynamic>? stats,
      String? flashSaleMessage,
    }) =>
        {
          if (sections != null) 'sections': sections,
          if (featured != null) 'featured': featured,
          if (stats != null) 'stats': stats,
          if (flashSaleMessage != null) 'flashSaleMessage': flashSaleMessage,
        };

    test('parses sections list', () {
      final data = StoreHubData.fromJson(legacyJson(sections: [
        {
          'id': 'sec1',
          'title': 'Test',
          'subtitle': '',
          'icon': 'store',
          'itemCount': '5',
          'preview': '',
        }
      ]));
      expect(data.sections.length, 1);
      expect(data.sections.first.id, 'sec1');
    });

    test('sections defaults to empty when absent', () {
      final data = StoreHubData.fromJson(legacyJson());
      expect(data.sections, isEmpty);
    });

    test('parses featured map', () {
      final data = StoreHubData.fromJson(legacyJson(
        featured: {
          'id': 'f1',
          'title': 'Deal',
          'subtitle': '',
          'icon': 'star',
        },
      ));
      expect(data.featured, isNotNull);
      expect(data.featured!.title, 'Deal');
    });

    test('featured is null when absent', () {
      final data = StoreHubData.fromJson(legacyJson());
      expect(data.featured, isNull);
    });

    test('parses stats', () {
      final data = StoreHubData.fromJson(legacyJson(
        stats: {'totalItems': '50', 'activeOffers': '5', 'newToday': '3'},
      ));
      expect(data.stats.totalItems, '50');
    });

    test('stats defaults to zeros when absent', () {
      final data = StoreHubData.fromJson(legacyJson());
      expect(data.stats.totalItems, '0');
    });

    test('parses flashSaleMessage', () {
      final data =
          StoreHubData.fromJson(legacyJson(flashSaleMessage: '50% off!'));
      expect(data.flashSaleMessage, '50% off!');
    });

    test('flashSaleMessage is null when absent', () {
      expect(StoreHubData.fromJson(legacyJson()).flashSaleMessage, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // StoreHubData.fromJson — backend format (featured is List)
  // -------------------------------------------------------------------------

  group('StoreHubData.fromJson — backend format (featured as List)', () {
    test('parses when featured is a List', () {
      final data = StoreHubData.fromJson({
        'featured': [
          {
            'sku': 'sku_001',
            'name': 'Super Pack',
            'description': 'Great deal',
            'itemType': 'auto_awesome',
          }
        ],
        'daily': [
          {'sku': 'daily_1', 'name': 'Daily item'},
        ],
      });
      expect(data.featured, isNotNull);
      expect(data.featured!.title, 'Super Pack');
      expect(data.featured!.sku, 'sku_001');
    });

    test('stats computed from featured + daily list lengths', () {
      final data = StoreHubData.fromJson({
        'featured': [
          {'sku': 'f1', 'name': 'Item 1'},
          {'sku': 'f2', 'name': 'Item 2'},
        ],
        'daily': [
          {'sku': 'd1', 'name': 'Daily 1'},
        ],
      });
      expect(data.stats.totalItems, '3'); // 2 featured + 1 daily
      expect(data.stats.activeOffers, '1'); // daily count
    });

    test('featured is null from fallback when featured list is empty', () {
      final data = StoreHubData.fromJson({'featured': <dynamic>[]});
      // falls back to StoreHubData.fallback.featured which is non-null
      expect(data.featured, isNotNull);
    });

    test('parses when categories key present (even without featured list)', () {
      final data = StoreHubData.fromJson({
        'categories': ['power-ups', 'themes'],
        'featured': null,
      });
      // should use backend format path; fallback sections used
      expect(data.sections, isNotEmpty);
    });

    test('parses nextResetAt as expiresAt', () {
      final data = StoreHubData.fromJson({
        'featured': [
          {
            'sku': 'sku_002',
            'name': 'Timed Deal',
            'description': '',
            'nextResetAt': '2025-12-01T00:00:00.000Z',
          }
        ],
      });
      expect(data.featured!.expiresAt, isNotNull);
      expect(data.featured!.expiresAt!.month, 12);
    });
  });

  // -------------------------------------------------------------------------
  // StoreHubData.fallback
  // -------------------------------------------------------------------------

  group('StoreHubData.fallback', () {
    test('returns 5 sections', () {
      expect(StoreHubData.fallback.sections.length, 5);
    });

    test('first section is game-store', () {
      expect(StoreHubData.fallback.sections.first.id, 'game-store');
    });

    test('featured is non-null', () {
      expect(StoreHubData.fallback.featured, isNotNull);
    });

    test('featured title is "Weekly Power-up Bundle"', () {
      expect(StoreHubData.fallback.featured!.title, 'Weekly Power-up Bundle');
    });

    test('stats.totalItems is "156"', () {
      expect(StoreHubData.fallback.stats.totalItems, '156');
    });

    test('flashSaleMessage is non-null', () {
      expect(StoreHubData.fallback.flashSaleMessage, isNotNull);
    });

    test('section ids are unique', () {
      final ids = StoreHubData.fallback.sections.map((s) => s.id).toSet();
      expect(ids.length, StoreHubData.fallback.sections.length);
    });
  });
}
