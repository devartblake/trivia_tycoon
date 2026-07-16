import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/models/store/store_offer_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // OfferItem.fromJson — legacy format
  // -------------------------------------------------------------------------

  group('OfferItem.fromJson — legacy format', () {
    Map<String, dynamic> makeJson({
      String? id,
      String? sku,
      String tab = 'Limited Time',
      String title = 'Premium Upgrade',
      String? name,
      String description = 'Great offer',
      String price = '4.99',
      String? originalPrice,
      int? discount,
      String icon = 'star',
      List<dynamic>? gradient,
      String buttonText = 'Buy Now',
      bool isPopular = false,
      String? tier,
      String? billingPeriod,
    }) =>
        {
          if (id != null) 'id': id,
          if (sku != null) 'sku': sku,
          'tab': tab,
          if (name != null) 'name': name else 'title': title,
          'description': description,
          'price': price,
          if (originalPrice != null) 'originalPrice': originalPrice,
          if (discount != null) 'discount': discount,
          'icon': icon,
          if (gradient != null) 'gradient': gradient,
          'buttonText': buttonText,
          'isPopular': isPopular,
          if (tier != null) 'tier': tier,
          if (billingPeriod != null) 'billingPeriod': billingPeriod,
        };

    test('parses id from id field', () {
      expect(OfferItem.fromJson(makeJson(id: 'offer_x')).id, 'offer_x');
    });

    test('prefers sku over id', () {
      expect(
          OfferItem.fromJson(makeJson(sku: 'sku_1', id: 'id_1')).id, 'sku_1');
    });

    test('tab defaults to "Limited Time" when absent', () {
      final json = makeJson(id: 'x');
      json.remove('tab');
      expect(OfferItem.fromJson(json).tab, 'Limited Time');
    });

    test('parses title', () {
      expect(OfferItem.fromJson(makeJson(id: 'x', title: 'Mega Deal')).title,
          'Mega Deal');
    });

    test('prefers name over title', () {
      expect(OfferItem.fromJson(makeJson(id: 'x', name: 'Flash Name')).title,
          'Flash Name');
    });

    test('parses description', () {
      expect(
          OfferItem.fromJson(makeJson(id: 'x', description: 'Best deal'))
              .description,
          'Best deal');
    });

    test('parses price from legacy price field', () {
      expect(
          OfferItem.fromJson(makeJson(id: 'x', price: '9.99')).price, '9.99');
    });

    test('parses originalPrice', () {
      expect(
          OfferItem.fromJson(makeJson(id: 'x', originalPrice: '19.99'))
              .originalPrice,
          '19.99');
    });

    test('originalPrice is null when absent', () {
      expect(OfferItem.fromJson(makeJson(id: 'x')).originalPrice, isNull);
    });

    test('parses discount', () {
      expect(OfferItem.fromJson(makeJson(id: 'x', discount: 50)).discount, 50);
    });

    test('discount is null when absent', () {
      expect(OfferItem.fromJson(makeJson(id: 'x')).discount, isNull);
    });

    test('parses icon', () {
      expect(OfferItem.fromJson(makeJson(id: 'x', icon: 'diamond')).icon,
          Icons.diamond);
    });

    test('unknown icon falls back to local_offer', () {
      expect(OfferItem.fromJson(makeJson(id: 'x', icon: 'unknown')).icon,
          Icons.local_offer);
    });

    test('buttonText defaults to "Buy Now" when absent', () {
      final json = makeJson(id: 'x');
      json.remove('buttonText');
      expect(OfferItem.fromJson(json).buttonText, 'Buy Now');
    });

    test('parses isPopular', () {
      expect(OfferItem.fromJson(makeJson(id: 'x', isPopular: true)).isPopular,
          isTrue);
    });

    test('isPopular defaults to false when absent', () {
      final json = makeJson(id: 'x');
      json.remove('isPopular');
      expect(OfferItem.fromJson(json).isPopular, isFalse);
    });

    test('parses tier', () {
      expect(
          OfferItem.fromJson(makeJson(id: 'x', tier: 'elite')).tier, 'elite');
    });

    test('tier is null when absent', () {
      expect(OfferItem.fromJson(makeJson(id: 'x')).tier, isNull);
    });

    test('parses billingPeriod', () {
      expect(
          OfferItem.fromJson(makeJson(id: 'x', billingPeriod: 'monthly'))
              .billingPeriod,
          'monthly');
    });
  });

  // -------------------------------------------------------------------------
  // OfferItem.fromJson — backend flash-sale format
  // -------------------------------------------------------------------------

  group('OfferItem.fromJson — backend format (salePriceCoins)', () {
    test('uses salePriceCoins as price string', () {
      final item = OfferItem.fromJson({
        'sku': 'flash_sku',
        'name': 'Flash Deal',
        'salePriceCoins': 299,
        'originalPriceCoins': 999,
        'discountPercent': 70,
      });
      expect(item.price, '299');
      expect(item.originalPrice, '999');
      expect(item.discount, 70);
    });

    test('tab defaults to "Limited Time" for flash sales', () {
      final item = OfferItem.fromJson({
        'sku': 'flash_sku2',
        'salePriceCoins': 100,
      });
      expect(item.tab, 'Limited Time');
    });
  });

  // -------------------------------------------------------------------------
  // FeaturedOffer.fromJson
  // -------------------------------------------------------------------------

  group('FeaturedOffer.fromJson', () {
    Map<String, dynamic> makeJson({
      String badgeText = 'FLASH SALE',
      String headline = '80% OFF',
      String subtitle = 'Premium',
      String description = 'Ends soon',
      String? expiresAt,
      String? endsAt,
      String buttonText = 'Claim Offer',
      String? sku,
    }) =>
        {
          'badgeText': badgeText,
          'headline': headline,
          'subtitle': subtitle,
          'description': description,
          if (expiresAt != null) 'expiresAt': expiresAt,
          if (endsAt != null) 'endsAt': endsAt,
          'buttonText': buttonText,
          if (sku != null) 'sku': sku,
        };

    test('parses badgeText', () {
      expect(FeaturedOffer.fromJson(makeJson(badgeText: 'SALE')).badgeText,
          'SALE');
    });

    test('badgeText defaults to "SALE" when absent', () {
      final json = makeJson();
      json.remove('badgeText');
      expect(FeaturedOffer.fromJson(json).badgeText, 'SALE');
    });

    test('parses headline', () {
      expect(FeaturedOffer.fromJson(makeJson(headline: '50% OFF')).headline,
          '50% OFF');
    });

    test('parses subtitle', () {
      expect(FeaturedOffer.fromJson(makeJson(subtitle: 'Daily Deal')).subtitle,
          'Daily Deal');
    });

    test('parses description', () {
      expect(
          FeaturedOffer.fromJson(makeJson(description: 'Great value'))
              .description,
          'Great value');
    });

    test('parses expiresAt', () {
      final o = FeaturedOffer.fromJson(
          makeJson(expiresAt: '2025-12-25T00:00:00.000Z'));
      expect(o.expiresAt, isNotNull);
      expect(o.expiresAt!.month, 12);
    });

    test('prefers endsAt over expiresAt', () {
      final o = FeaturedOffer.fromJson(makeJson(
          endsAt: '2025-11-01T00:00:00.000Z',
          expiresAt: '2025-12-01T00:00:00.000Z'));
      expect(o.expiresAt!.month, 11);
    });

    test('expiresAt is null when absent', () {
      expect(FeaturedOffer.fromJson(makeJson()).expiresAt, isNull);
    });

    test('parses buttonText', () {
      expect(FeaturedOffer.fromJson(makeJson(buttonText: 'Get It')).buttonText,
          'Get It');
    });

    test('buttonText defaults to "Claim Offer" when absent', () {
      final json = makeJson();
      json.remove('buttonText');
      expect(FeaturedOffer.fromJson(json).buttonText, 'Claim Offer');
    });

    test('parses sku', () {
      expect(FeaturedOffer.fromJson(makeJson(sku: 'SKU99')).sku, 'SKU99');
    });

    test('sku is null when absent', () {
      expect(FeaturedOffer.fromJson(makeJson()).sku, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // FeaturedOffer — countdownLabel
  // -------------------------------------------------------------------------

  group('FeaturedOffer — countdownLabel', () {
    FeaturedOffer offer({DateTime? expiresAt}) => FeaturedOffer(
          badgeText: 'SALE',
          headline: 'Test',
          subtitle: '',
          description: '',
          expiresAt: expiresAt,
          buttonText: 'Buy',
        );

    test('returns "" when expiresAt is null', () {
      expect(offer().countdownLabel, '');
    });

    test('returns "Expired" when past', () {
      expect(
          offer(expiresAt: DateTime.now().subtract(const Duration(hours: 1)))
              .countdownLabel,
          'Expired');
    });

    test('returns "N days left" when > 1 day', () {
      expect(
          offer(expiresAt: DateTime.now().add(const Duration(days: 3)))
              .countdownLabel,
          contains('days left'));
    });

    test('returns "Nh left" when > 1 hour', () {
      expect(
          offer(expiresAt: DateTime.now().add(const Duration(hours: 3)))
              .countdownLabel,
          contains('h left'));
    });

    test('returns "Nm left" when > 1 minute and <= 1 hour', () {
      expect(
          offer(expiresAt: DateTime.now().add(const Duration(minutes: 15)))
              .countdownLabel,
          contains('m left'));
    });

    test('returns "Ending soon" when <= 1 minute', () {
      expect(
          offer(expiresAt: DateTime.now().add(const Duration(seconds: 30)))
              .countdownLabel,
          'Ending soon');
    });
  });

  // -------------------------------------------------------------------------
  // StoreOffersData.fromJson
  // -------------------------------------------------------------------------

  group('StoreOffersData.fromJson', () {
    test('parses featured', () {
      final data = StoreOffersData.fromJson({
        'featured': {
          'badgeText': 'HOT',
          'headline': '70% OFF',
          'subtitle': 'Today only',
          'description': '',
          'buttonText': 'Grab It',
        },
        'tabs': ['A', 'B'],
        'offers': [],
      });
      expect(data.featured, isNotNull);
      expect(data.featured!.badgeText, 'HOT');
    });

    test('featured is null when absent', () {
      final data = StoreOffersData.fromJson({'tabs': [], 'offers': []});
      expect(data.featured, isNull);
    });

    test('parses tabs', () {
      final data = StoreOffersData.fromJson({
        'tabs': ['Limited Time', 'Premium'],
        'offers': [],
      });
      expect(data.tabs, ['Limited Time', 'Premium']);
    });

    test('tabs default to 4 standard tabs when absent', () {
      final data = StoreOffersData.fromJson({'offers': []});
      expect(data.tabs.length, 4);
      expect(data.tabs, contains('Limited Time'));
    });

    test('parses offers list', () {
      final data = StoreOffersData.fromJson({
        'offers': [
          {
            'id': 'o1',
            'tab': 'Daily Deals',
            'title': 'Energy Deal',
            'description': '',
            'price': '1.99',
            'icon': 'flash_on',
            'buttonText': 'Buy',
          },
        ],
      });
      expect(data.offers.length, 1);
      expect(data.offers.first.tab, 'Daily Deals');
    });

    test('offers defaults to empty when absent', () {
      final data = StoreOffersData.fromJson({});
      expect(data.offers, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // StoreOffersData — offersForTab
  // -------------------------------------------------------------------------

  group('StoreOffersData — offersForTab', () {
    test('returns only offers matching the tab', () {
      const offer1 = OfferItem(
        id: 'o1',
        tab: 'Daily Deals',
        title: 'A',
        description: '',
        price: '1',
        icon: Icons.star,
        gradient:
            LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)]),
        buttonText: 'Buy',
      );
      const offer2 = OfferItem(
        id: 'o2',
        tab: 'Premium',
        title: 'B',
        description: '',
        price: '2',
        icon: Icons.star,
        gradient:
            LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)]),
        buttonText: 'Buy',
      );
      final data = StoreOffersData(
        tabs: const ['Daily Deals', 'Premium'],
        offers: const [offer1, offer2],
      );
      expect(data.offersForTab('Daily Deals').length, 1);
      expect(data.offersForTab('Daily Deals').first.id, 'o1');
      expect(data.offersForTab('Premium').first.id, 'o2');
    });

    test('returns empty for unknown tab', () {
      final data = const StoreOffersData(tabs: [], offers: []);
      expect(data.offersForTab('Bundles'), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // StoreOffersData.fallback
  // -------------------------------------------------------------------------

  group('StoreOffersData.fallback', () {
    test('has non-null featured', () {
      expect(StoreOffersData.fallback.featured, isNotNull);
    });

    test('has 4 default tabs', () {
      expect(StoreOffersData.fallback.tabs.length, 4);
    });

    test('has offers', () {
      expect(StoreOffersData.fallback.offers, isNotEmpty);
    });

    test('all offer tabs are within the tabs list', () {
      final tabs = StoreOffersData.fallback.tabs.toSet();
      for (final offer in StoreOffersData.fallback.offers) {
        expect(tabs, contains(offer.tab),
            reason: 'Offer ${offer.id} tab "${offer.tab}" not in tabs list');
      }
    });
  });
}
