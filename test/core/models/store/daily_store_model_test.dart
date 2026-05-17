import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/store/daily_store_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // dailyItemIcon
  // -------------------------------------------------------------------------

  group('dailyItemIcon', () {
    test('"power_up" → Icons.bolt', () {
      expect(dailyItemIcon('power_up'), Icons.bolt);
    });

    test('"cosmetic" → Icons.palette', () {
      expect(dailyItemIcon('cosmetic'), Icons.palette);
    });

    test('"avatar" → Icons.face', () {
      expect(dailyItemIcon('avatar'), Icons.face);
    });

    test('"bundle" → Icons.card_giftcard', () {
      expect(dailyItemIcon('bundle'), Icons.card_giftcard);
    });

    test('"currency" → Icons.monetization_on', () {
      expect(dailyItemIcon('currency'), Icons.monetization_on);
    });

    test('unknown → Icons.auto_awesome', () {
      expect(dailyItemIcon('other'), Icons.auto_awesome);
    });

    test('null → Icons.auto_awesome', () {
      expect(dailyItemIcon(null), Icons.auto_awesome);
    });
  });

  // -------------------------------------------------------------------------
  // dailyItemColor
  // -------------------------------------------------------------------------

  group('dailyItemColor', () {
    test('"power_up" → 0xFF8B5CF6', () {
      expect(dailyItemColor('power_up'), const Color(0xFF8B5CF6));
    });

    test('"cosmetic" → 0xFFEC4899', () {
      expect(dailyItemColor('cosmetic'), const Color(0xFFEC4899));
    });

    test('"avatar" → 0xFF10B981', () {
      expect(dailyItemColor('avatar'), const Color(0xFF10B981));
    });

    test('"bundle" → 0xFFF59E0B', () {
      expect(dailyItemColor('bundle'), const Color(0xFFF59E0B));
    });

    test('"currency" → 0xFF6366F1', () {
      expect(dailyItemColor('currency'), const Color(0xFF6366F1));
    });

    test('unknown → 0xFF64748B', () {
      expect(dailyItemColor('other'), const Color(0xFF64748B));
    });

    test('null → 0xFF64748B', () {
      expect(dailyItemColor(null), const Color(0xFF64748B));
    });
  });

  // -------------------------------------------------------------------------
  // DailyStoreItem.fromJson — nested stock
  // -------------------------------------------------------------------------

  group('DailyStoreItem.fromJson — nested stock', () {
    Map<String, dynamic> makeJson({
      String? sku,
      String? id,
      String? name,
      String? title,
      String description = 'A great item',
      int price = 200,
      String? priceCoins,
      String currency = 'coins',
      String? iconPath,
      String? category,
      bool owned = false,
      Map<String, dynamic>? stock,
    }) =>
        {
          if (sku != null) 'sku': sku,
          if (id != null) 'id': id,
          if (name != null) 'name': name,
          if (title != null) 'title': title,
          'description': description,
          if (priceCoins != null) 'priceCoins': priceCoins else 'price': price,
          'currency': currency,
          if (iconPath != null) 'iconPath': iconPath,
          if (category != null) 'category': category,
          'owned': owned,
          if (stock != null) 'stock': stock,
        };

    test('parses sku', () {
      expect(DailyStoreItem.fromJson(makeJson(sku: 'daily:xp')).sku, 'daily:xp');
    });

    test('uses id as sku fallback', () {
      expect(DailyStoreItem.fromJson(makeJson(id: 'id_sku')).sku, 'id_sku');
    });

    test('parses title from name', () {
      expect(
          DailyStoreItem.fromJson(makeJson(name: 'Double XP')).title, 'Double XP');
    });

    test('parses title from title field', () {
      expect(DailyStoreItem.fromJson(makeJson(title: 'Hint Pack')).title,
          'Hint Pack');
    });

    test('parses description', () {
      expect(DailyStoreItem.fromJson(makeJson(description: 'Great')).description,
          'Great');
    });

    test('parses price', () {
      expect(DailyStoreItem.fromJson(makeJson(price: 150)).price, 150);
    });

    test('parses priceCoins and sets currency to coins', () {
      final item = DailyStoreItem.fromJson({
        'sku': 's1',
        'priceCoins': 300,
      });
      expect(item.price, 300);
      expect(item.currency, 'coins');
    });

    test('parses currency', () {
      expect(DailyStoreItem.fromJson(makeJson(currency: 'diamonds')).currency,
          'diamonds');
    });

    test('parses iconPath', () {
      expect(
          DailyStoreItem.fromJson(makeJson(iconPath: 'assets/icon.png')).iconPath,
          'assets/icon.png');
    });

    test('iconPath is null when absent', () {
      expect(DailyStoreItem.fromJson(makeJson()).iconPath, isNull);
    });

    test('parses category from itemType', () {
      final item = DailyStoreItem.fromJson({
        'sku': 's1',
        'itemType': 'power_up',
        'price': 0,
      });
      expect(item.category, 'power_up');
    });

    test('parses category from category fallback', () {
      expect(DailyStoreItem.fromJson(makeJson(category: 'cosmetic')).category,
          'cosmetic');
    });

    test('parses owned', () {
      expect(DailyStoreItem.fromJson(makeJson(owned: true)).owned, isTrue);
    });

    test('owned defaults to false when absent', () {
      final map = makeJson();
      map.remove('owned');
      expect(DailyStoreItem.fromJson(map).owned, isFalse);
    });

    test('parses nested stock object', () {
      final item = DailyStoreItem.fromJson(
          makeJson(stock: {'isSoldOut': true, 'isUnlimited': false}));
      expect(item.stock.isSoldOut, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // DailyStoreItem.fromJson — flat backend fields (no nested stock)
  // -------------------------------------------------------------------------

  group('DailyStoreItem.fromJson — flat backend format', () {
    test('builds stock from flat resetInterval → per_user policy', () {
      final item = DailyStoreItem.fromJson({
        'sku': 'flat1',
        'resetInterval': 'daily',
        'remainingQuantity': 3,
        'nextResetAt': '2025-06-02T00:00:00.000Z',
      });
      expect(item.stock.policyType, 'per_user');
      expect(item.stock.remainingQuantity, 3);
    });

    test('isUnlimited true when remainingQuantity is -1', () {
      final item = DailyStoreItem.fromJson({
        'sku': 'flat2',
        'remainingQuantity': -1,
      });
      expect(item.stock.isUnlimited, isTrue);
    });

    test('isUnlimited true when no resetInterval', () {
      final item = DailyStoreItem.fromJson({'sku': 'flat3'});
      expect(item.stock.isUnlimited, isTrue);
    });

    test('isSoldOut from soldOut field', () {
      final item = DailyStoreItem.fromJson({
        'sku': 'flat4',
        'soldOut': true,
        'resetInterval': 'daily',
      });
      expect(item.stock.isSoldOut, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // DailyStoreItem — computed: isFree / isCoins
  // -------------------------------------------------------------------------

  group('DailyStoreItem — isFree / isCoins', () {
    test('isFree true when price is 0', () {
      final item = DailyStoreItem.fromJson({'sku': 'free', 'price': 0});
      expect(item.isFree, isTrue);
    });

    test('isFree false when price > 0', () {
      final item = DailyStoreItem.fromJson({'sku': 'paid', 'price': 100});
      expect(item.isFree, isFalse);
    });

    test('isCoins true when currency is coins', () {
      final item = DailyStoreItem.fromJson(
          {'sku': 'c', 'currency': 'coins', 'price': 50});
      expect(item.isCoins, isTrue);
    });

    test('isCoins false when currency is diamonds', () {
      final item = DailyStoreItem.fromJson(
          {'sku': 'c', 'currency': 'diamonds', 'price': 50});
      expect(item.isCoins, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // DailyStoreData.fromJson
  // -------------------------------------------------------------------------

  group('DailyStoreData.fromJson', () {
    test('parses items list', () {
      final data = DailyStoreData.fromJson({
        'items': [
          {'sku': 'i1', 'name': 'Item 1', 'price': 100, 'currency': 'coins'},
          {'sku': 'i2', 'name': 'Item 2', 'price': 200, 'currency': 'coins'},
        ],
        'resetsAt': '2025-06-02T00:00:00.000Z',
      });
      expect(data.items.length, 2);
      expect(data.items.first.sku, 'i1');
    });

    test('items defaults to empty when absent', () {
      final data =
          DailyStoreData.fromJson({'resetsAt': '2025-06-02T00:00:00.000Z'});
      expect(data.items, isEmpty);
    });

    test('parses resetsAt as nextResetAt', () {
      final data =
          DailyStoreData.fromJson({'resetsAt': '2025-09-01T00:00:00.000Z'});
      expect(data.nextResetAt.month, 9);
    });

    test('parses nextResetAt as fallback', () {
      final data =
          DailyStoreData.fromJson({'nextResetAt': '2025-10-01T00:00:00.000Z'});
      expect(data.nextResetAt.month, 10);
    });

    test('nextResetAt defaults to 24h from now when absent', () {
      final before = DateTime.now().toUtc().add(const Duration(hours: 23));
      final after = DateTime.now().toUtc().add(const Duration(hours: 25));
      final data = DailyStoreData.fromJson({});
      expect(data.nextResetAt.isAfter(before), isTrue);
      expect(data.nextResetAt.isBefore(after), isTrue);
    });

    test('parses resetIntervalSeconds', () {
      final data = DailyStoreData.fromJson({
        'resetsAt': '2025-06-02T00:00:00.000Z',
        'resetIntervalSeconds': 43200,
      });
      expect(data.resetIntervalSeconds, 43200);
    });

    test('resetIntervalSeconds defaults to 86400 when absent', () {
      final data =
          DailyStoreData.fromJson({'resetsAt': '2025-06-02T00:00:00.000Z'});
      expect(data.resetIntervalSeconds, 86400);
    });

    test('parses bannerMessage', () {
      final data = DailyStoreData.fromJson({
        'resetsAt': '2025-06-02T00:00:00.000Z',
        'bannerMessage': 'Flash sale today!',
      });
      expect(data.bannerMessage, 'Flash sale today!');
    });

    test('bannerMessage is null when absent', () {
      final data =
          DailyStoreData.fromJson({'resetsAt': '2025-06-02T00:00:00.000Z'});
      expect(data.bannerMessage, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // DailyStoreData — isExpired / timeUntilReset
  // -------------------------------------------------------------------------

  group('DailyStoreData — isExpired', () {
    test('false when nextResetAt is in the future', () {
      final data = DailyStoreData(
        items: const [],
        nextResetAt: DateTime.now().toUtc().add(const Duration(hours: 10)),
        resetIntervalSeconds: 86400,
      );
      expect(data.isExpired, isFalse);
    });

    test('true when nextResetAt is in the past', () {
      final data = DailyStoreData(
        items: const [],
        nextResetAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        resetIntervalSeconds: 86400,
      );
      expect(data.isExpired, isTrue);
    });
  });

  group('DailyStoreData — timeUntilReset', () {
    test('positive duration when future reset', () {
      final data = DailyStoreData(
        items: const [],
        nextResetAt: DateTime.now().toUtc().add(const Duration(hours: 5)),
        resetIntervalSeconds: 86400,
      );
      expect(data.timeUntilReset.isNegative, isFalse);
      expect(data.timeUntilReset.inHours, greaterThan(4));
    });

    test('negative duration when past reset', () {
      final data = DailyStoreData(
        items: const [],
        nextResetAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        resetIntervalSeconds: 86400,
      );
      expect(data.timeUntilReset.isNegative, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // DailyStoreData.fallback
  // -------------------------------------------------------------------------

  group('DailyStoreData.fallback', () {
    test('has 4 items', () {
      expect(DailyStoreData.fallback.items.length, 4);
    });

    test('all items have non-empty sku', () {
      for (final item in DailyStoreData.fallback.items) {
        expect(item.sku, isNotEmpty);
      }
    });

    test('nextResetAt is in the future', () {
      expect(
          DailyStoreData.fallback.nextResetAt.isAfter(DateTime.now().toUtc()),
          isTrue);
    });

    test('resetIntervalSeconds is 86400', () {
      expect(DailyStoreData.fallback.resetIntervalSeconds, 86400);
    });

    test('bannerMessage is non-null', () {
      expect(DailyStoreData.fallback.bannerMessage, isNotNull);
    });
  });
}
