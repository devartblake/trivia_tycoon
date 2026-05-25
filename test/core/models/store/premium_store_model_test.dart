import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/store/premium_store_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // AdRemovePlan.fromJson
  // -------------------------------------------------------------------------

  group('AdRemovePlan.fromJson', () {
    Map<String, dynamic> makeJson({
      String id = 'ad-free-365',
      String? title,
      String? subtitle,
      String price = r'$5.99',
      String? priceLabel,
      String? durationLabel,
      String badge = 'Best Value',
      String? accentColor,
      bool isBestValue = false,
      String sku = '',
    }) =>
        {
          'id': id,
          if (title != null) 'title': title,
          if (subtitle != null) 'subtitle': subtitle,
          if (priceLabel != null) 'priceLabel': priceLabel else 'price': price,
          if (durationLabel != null) 'durationLabel': durationLabel,
          'badge': badge,
          if (accentColor != null) 'accentColor': accentColor,
          'isBestValue': isBestValue,
          'sku': sku,
        };

    test('parses id', () {
      expect(AdRemovePlan.fromJson(makeJson(id: 'plan_x')).id, 'plan_x');
    });

    test('parses price from price field', () {
      expect(AdRemovePlan.fromJson(makeJson(price: r'$9.99')).price, r'$9.99');
    });

    test('prefers priceLabel when price absent', () {
      final map = makeJson();
      map.remove('price');
      map['priceLabel'] = r'$4.99';
      expect(AdRemovePlan.fromJson(map).price, r'$4.99');
    });

    test('parses durationLabel', () {
      expect(
          AdRemovePlan.fromJson(makeJson(durationLabel: '7 DAYS')).durationLabel,
          '7 DAYS');
    });

    test('durationLabel falls back to title when absent', () {
      final plan = AdRemovePlan.fromJson(makeJson(title: 'Annual Plan'));
      expect(plan.durationLabel, 'Annual Plan');
    });

    test('parses badge', () {
      expect(AdRemovePlan.fromJson(makeJson(badge: 'Hot Deal')).badge, 'Hot Deal');
    });

    test('badge defaults to "" when absent', () {
      final map = makeJson();
      map.remove('badge');
      expect(AdRemovePlan.fromJson(map).badge, '');
    });

    test('parses isBestValue', () {
      expect(
          AdRemovePlan.fromJson(makeJson(isBestValue: true)).isBestValue, isTrue);
    });

    test('isBestValue defaults to false when absent', () {
      final map = makeJson();
      map.remove('isBestValue');
      expect(AdRemovePlan.fromJson(map).isBestValue, isFalse);
    });

    test('parses accentColor via resolveColor', () {
      expect(AdRemovePlan.fromJson(makeJson(accentColor: 'green')).accentColor,
          const Color(0xFF10B981));
    });

    test('parses sku', () {
      expect(AdRemovePlan.fromJson(makeJson(sku: 'ad_sku_1')).sku, 'ad_sku_1');
    });
  });

  // -------------------------------------------------------------------------
  // AdRemovePlan — displayTitle / displaySubtitle / tier / billingPeriod
  // -------------------------------------------------------------------------

  group('AdRemovePlan — computed', () {
    test('displayTitle returns title when non-empty', () {
      final plan = AdRemovePlan.fromJson({
        'id': 'p1',
        'title': 'Annual Plan',
        'durationLabel': '365 DAYS',
        'price': r'$5.99',
        'badge': '',
        'accentColor': 'green',
        'isBestValue': false,
      });
      expect(plan.displayTitle, 'Annual Plan');
    });

    test('displayTitle falls back to durationLabel when title empty', () {
      final plan = AdRemovePlan.fromJson({
        'id': 'p2',
        'title': '',
        'durationLabel': '28 DAYS',
        'price': r'$3.99',
        'badge': '',
        'accentColor': 'blue',
        'isBestValue': false,
      });
      expect(plan.displayTitle, '28 DAYS');
    });

    test('displaySubtitle returns subtitle', () {
      final plan = AdRemovePlan.fromJson({
        'id': 'p3',
        'title': '',
        'subtitle': 'Best deal ever',
        'price': r'$1.99',
        'badge': '',
        'accentColor': 'purple',
        'isBestValue': false,
      });
      expect(plan.displaySubtitle, 'Best deal ever');
    });

    test('tier returns "elite" when id contains elite', () {
      const plan = AdRemovePlan(
        id: 'elite-monthly',
        durationLabel: '30 DAYS',
        price: r'$9.99',
        badge: '',
        accentColor: Color(0xFF10B981),
        isBestValue: false,
      );
      expect(plan.tier, 'elite');
    });

    test('tier returns "premium" when sku contains premium', () {
      const plan = AdRemovePlan(
        id: 'basic',
        durationLabel: '30 DAYS',
        price: r'$9.99',
        badge: '',
        accentColor: Color(0xFF10B981),
        isBestValue: false,
        sku: 'premium-monthly',
      );
      expect(plan.tier, 'premium');
    });

    test('tier returns null when no elite/premium in id or sku', () {
      const plan = AdRemovePlan(
        id: 'ad-free-7',
        durationLabel: '7 DAYS',
        price: r'$1.99',
        badge: '',
        accentColor: Color(0xFF8B5CF6),
        isBestValue: false,
      );
      expect(plan.tier, isNull);
    });

    test('billingPeriod returns "seasonal" when id contains season', () {
      const plan = AdRemovePlan(
        id: 'seasonal-plan',
        durationLabel: '90 DAYS',
        price: r'$19.99',
        badge: '',
        accentColor: Color(0xFF10B981),
        isBestValue: false,
      );
      expect(plan.billingPeriod, 'seasonal');
    });

    test('billingPeriod returns "monthly" when id contains monthly', () {
      const plan = AdRemovePlan(
        id: 'monthly-plan',
        durationLabel: '30 DAYS',
        price: r'$9.99',
        badge: '',
        accentColor: Color(0xFF6366F1),
        isBestValue: false,
      );
      expect(plan.billingPeriod, 'monthly');
    });

    test('billingPeriod returns null for 7/28/365 day plans', () {
      const plan = AdRemovePlan(
        id: 'ad-free-365',
        durationLabel: '365 DAYS',
        price: r'$5.99',
        badge: '',
        accentColor: Color(0xFF10B981),
        isBestValue: true,
      );
      expect(plan.billingPeriod, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AdFreeConfig.fromJson
  // -------------------------------------------------------------------------

  group('AdFreeConfig.fromJson', () {
    test('parses plans', () {
      final config = AdFreeConfig.fromJson({
        'plans': [
          {
            'id': 'p1',
            'price': r'$5.99',
            'durationLabel': '365 DAYS',
            'badge': 'Best Value',
            'accentColor': 'green',
            'isBestValue': true,
          },
          {
            'id': 'p2',
            'price': r'$1.99',
            'durationLabel': '7 DAYS',
            'badge': '',
            'accentColor': 'blue',
            'isBestValue': false,
          },
        ],
        'benefits': ['No ads', 'Faster load'],
      });
      expect(config.plans.length, 2);
      expect(config.benefits, ['No ads', 'Faster load']);
    });

    test('parses title and subtitle', () {
      final config = AdFreeConfig.fromJson({
        'title': 'Go Ad-Free',
        'subtitle': 'Enjoy uninterrupted play',
        'plans': [],
        'benefits': [],
      });
      expect(config.title, 'Go Ad-Free');
      expect(config.subtitle, 'Enjoy uninterrupted play');
    });

    test('plans defaults to empty when absent', () {
      expect(AdFreeConfig.fromJson({}).plans, isEmpty);
    });

    test('benefits defaults to empty when absent', () {
      expect(AdFreeConfig.fromJson({}).benefits, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // AdFreeConfig — defaultPurchasePlan
  // -------------------------------------------------------------------------

  group('AdFreeConfig — defaultPurchasePlan', () {
    test('returns null when no plans', () {
      expect(AdFreeConfig.fromJson({}).defaultPurchasePlan, isNull);
    });

    test('returns bestValue plan when present', () {
      const config = AdFreeConfig(
        plans: [
          AdRemovePlan(
            id: 'cheap',
            durationLabel: '7 DAYS',
            price: r'$1.99',
            badge: '',
            accentColor: Color(0xFF8B5CF6),
            isBestValue: false,
          ),
          AdRemovePlan(
            id: 'annual',
            durationLabel: '365 DAYS',
            price: r'$5.99',
            badge: 'Best Value',
            accentColor: Color(0xFF10B981),
            isBestValue: true,
          ),
        ],
        benefits: [],
      );
      expect(config.defaultPurchasePlan!.id, 'annual');
    });

    test('returns first plan when no bestValue plan', () {
      const config = AdFreeConfig(
        plans: [
          AdRemovePlan(
            id: 'first',
            durationLabel: '7 DAYS',
            price: r'$1.99',
            badge: '',
            accentColor: Color(0xFF8B5CF6),
            isBestValue: false,
          ),
          AdRemovePlan(
            id: 'second',
            durationLabel: '28 DAYS',
            price: r'$3.99',
            badge: '',
            accentColor: Color(0xFF6366F1),
            isBestValue: false,
          ),
        ],
        benefits: [],
      );
      expect(config.defaultPurchasePlan!.id, 'first');
    });
  });

  // -------------------------------------------------------------------------
  // AdFreeConfig.fallback
  // -------------------------------------------------------------------------

  group('AdFreeConfig.fallback', () {
    test('has 3 plans', () {
      expect(AdFreeConfig.fallback.plans.length, 3);
    });

    test('has 4 benefits', () {
      expect(AdFreeConfig.fallback.benefits.length, 4);
    });

    test('first plan is bestValue (365 days)', () {
      expect(AdFreeConfig.fallback.plans.first.isBestValue, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SaleBenefitItem.fromJson
  // -------------------------------------------------------------------------

  group('SaleBenefitItem.fromJson', () {
    test('parses value and label', () {
      final item = SaleBenefitItem.fromJson({
        'icon': 'star',
        'value': '5',
        'label': 'Premium Features',
        'color': 'green',
      });
      expect(item.value, '5');
      expect(item.label, 'Premium Features');
    });

    test('defaults value to "" when absent', () {
      expect(SaleBenefitItem.fromJson({'icon': 'star', 'color': 'blue'}).value,
          '');
    });

    test('parses icon', () {
      expect(
          SaleBenefitItem.fromJson(
              {'icon': 'star', 'value': '', 'label': '', 'color': 'blue'}).icon,
          Icons.star);
    });

    test('unknown icon falls back to star', () {
      expect(
          SaleBenefitItem.fromJson(
              {'icon': 'unk', 'value': '', 'label': '', 'color': 'blue'}).icon,
          Icons.star);
    });

    test('parses color', () {
      expect(
          SaleBenefitItem.fromJson(
              {'value': '', 'label': '', 'color': 'purple'}).color,
          const Color(0xFF8B5CF6));
    });
  });

  // -------------------------------------------------------------------------
  // SaleInfoData.fromJson
  // -------------------------------------------------------------------------

  group('SaleInfoData.fromJson', () {
    test('parses badgeText', () {
      expect(SaleInfoData.fromJson({'badgeText': 'HOT DEAL'}).badgeText,
          'HOT DEAL');
    });

    test('badgeText defaults to "FLASH SALE" when absent', () {
      expect(SaleInfoData.fromJson({}).badgeText, 'FLASH SALE');
    });

    test('parses discount, originalPrice, salePrice', () {
      final s = SaleInfoData.fromJson({
        'discount': '80% OFF',
        'originalPrice': r'$10',
        'salePrice': r'$1.99',
      });
      expect(s.discount, '80% OFF');
      expect(s.originalPrice, r'$10');
      expect(s.salePrice, r'$1.99');
    });

    test('parses benefits list', () {
      final s = SaleInfoData.fromJson({
        'benefits': [
          {'icon': 'star', 'value': '3', 'label': 'Features', 'color': 'green'},
        ],
      });
      expect(s.benefits.length, 1);
    });

    test('parses expiresAt', () {
      final s =
          SaleInfoData.fromJson({'expiresAt': '2025-12-01T00:00:00.000Z'});
      expect(s.expiresAt, isNotNull);
    });

    test('parses buttonText', () {
      expect(SaleInfoData.fromJson({'buttonText': 'Grab It'}).buttonText,
          'Grab It');
    });

    test('buttonText defaults to "Claim This Deal" when absent', () {
      expect(SaleInfoData.fromJson({}).buttonText, 'Claim This Deal');
    });

    test('parses sku and tier and billingPeriod', () {
      final s = SaleInfoData.fromJson({
        'sku': 'ELITE1',
        'tier': 'elite',
        'billingPeriod': 'monthly',
      });
      expect(s.sku, 'ELITE1');
      expect(s.tier, 'elite');
      expect(s.billingPeriod, 'monthly');
    });
  });

  // -------------------------------------------------------------------------
  // RewardCard.fromJson
  // -------------------------------------------------------------------------

  group('RewardCard.fromJson', () {
    test('parses id from id field', () {
      expect(
          RewardCard.fromJson({'id': 'rc1', 'isAvailable': false}).id, 'rc1');
    });

    test('parses id from rewardId fallback', () {
      expect(RewardCard.fromJson({'rewardId': 'rc2', 'isAvailable': false}).id,
          'rc2');
    });

    test('parses title', () {
      expect(
          RewardCard.fromJson(
                  {'id': 'rc1', 'title': 'Daily Check-in', 'isAvailable': true})
              .title,
          'Daily Check-in');
    });

    test('parses reward from reward field', () {
      expect(
          RewardCard.fromJson(
                  {'id': 'rc1', 'reward': '500 Coins', 'isAvailable': false})
              .reward,
          '500 Coins');
    });

    test('parses reward from rewardLabel fallback', () {
      expect(
          RewardCard.fromJson(
                  {'id': 'rc1', 'rewardLabel': '200 XP', 'isAvailable': false})
              .reward,
          '200 XP');
    });

    test('parses progress', () {
      expect(
          RewardCard.fromJson(
              {'id': 'rc1', 'progress': 0.75, 'isAvailable': true}).progress,
          closeTo(0.75, 0.001));
    });

    test('progress is null when absent', () {
      expect(RewardCard.fromJson({'id': 'rc1', 'isAvailable': false}).progress,
          isNull);
    });

    test('parses isAvailable', () {
      expect(
          RewardCard.fromJson({'id': 'rc1', 'isAvailable': true}).isAvailable,
          isTrue);
    });

    test('parses isAvailable from isClaimAvailable fallback', () {
      expect(
          RewardCard.fromJson({'id': 'rc1', 'isClaimAvailable': true})
              .isAvailable,
          isTrue);
    });

    test('isAvailable defaults to false when absent', () {
      expect(RewardCard.fromJson({'id': 'rc1'}).isAvailable, isFalse);
    });

    test('parses gradient from list', () {
      final card = RewardCard.fromJson({
        'id': 'rc1',
        'gradient': ['#FF0000', '#0000FF'],
        'isAvailable': false,
      });
      expect(card.gradient.colors.first, const Color(0xFFFF0000));
    });

    test('parses gradient from gradientStart/gradientEnd', () {
      final card = RewardCard.fromJson({
        'id': 'rc1',
        'gradientStart': '#10B981',
        'gradientEnd': '#059669',
        'isAvailable': false,
      });
      expect(card.gradient.colors.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // RewardCenterData.fromJson
  // -------------------------------------------------------------------------

  group('RewardCenterData.fromJson', () {
    test('parses cards list', () {
      final data = RewardCenterData.fromJson({
        'cards': [
          {'id': 'c1', 'isAvailable': true},
          {'id': 'c2', 'isAvailable': false},
        ],
      });
      expect(data.cards.length, 2);
    });

    test('cards defaults to empty when absent', () {
      expect(RewardCenterData.fromJson({}).cards, isEmpty);
    });

    test('completedCount inferred from !isAvailable when absent', () {
      final data = RewardCenterData.fromJson({
        'cards': [
          {'id': 'c1', 'isAvailable': true},
          {'id': 'c2', 'isAvailable': false},
          {'id': 'c3', 'isAvailable': false},
        ],
      });
      expect(data.completedCount, 2);
    });

    test('completedCount uses JSON field when present', () {
      final data = RewardCenterData.fromJson({
        'cards': [],
        'completedCount': 7,
        'totalCount': 10,
      });
      expect(data.completedCount, 7);
    });

    test('totalCount inferred from cards.length when absent', () {
      final data = RewardCenterData.fromJson({
        'cards': [
          {'id': 'c1', 'isAvailable': true},
          {'id': 'c2', 'isAvailable': true},
        ],
      });
      expect(data.totalCount, 2);
    });
  });

  // -------------------------------------------------------------------------
  // PremiumStoreData.fromJson
  // -------------------------------------------------------------------------

  group('PremiumStoreData.fromJson', () {
    test('uses fallback adFree when absent', () {
      final data = PremiumStoreData.fromJson({});
      expect(data.adFree.plans.length, AdFreeConfig.fallback.plans.length);
    });

    test('parses adFree when present', () {
      final data = PremiumStoreData.fromJson({
        'adFree': {
          'plans': [
            {
              'id': 'p1',
              'price': r'$1.99',
              'durationLabel': '7 DAYS',
              'badge': '',
              'accentColor': 'blue',
              'isBestValue': false,
            }
          ],
          'benefits': ['No ads'],
        },
      });
      expect(data.adFree.plans.length, 1);
    });

    test('saleInfo is null when absent', () {
      expect(PremiumStoreData.fromJson({}).saleInfo, isNull);
    });

    test('parses saleInfo when present', () {
      final data = PremiumStoreData.fromJson({
        'saleInfo': {
          'badgeText': 'SALE',
          'discount': '50% OFF',
          'originalPrice': r'$10',
          'salePrice': r'$5',
          'buttonText': 'Grab It',
        },
      });
      expect(data.saleInfo, isNotNull);
      expect(data.saleInfo!.badgeText, 'SALE');
    });

    test('uses fallback rewardCenter when absent', () {
      final data = PremiumStoreData.fromJson({});
      expect(data.rewardCenter.cards.length,
          RewardCenterData.fallback.cards.length);
    });
  });

  // -------------------------------------------------------------------------
  // PremiumStoreData.fallback
  // -------------------------------------------------------------------------

  group('PremiumStoreData.fallback', () {
    test('has non-null adFree with plans', () {
      expect(PremiumStoreData.fallback.adFree.plans, isNotEmpty);
    });

    test('has non-null saleInfo', () {
      expect(PremiumStoreData.fallback.saleInfo, isNotNull);
    });

    test('has non-null rewardCenter with cards', () {
      expect(PremiumStoreData.fallback.rewardCenter.cards, isNotEmpty);
    });
  });
}
