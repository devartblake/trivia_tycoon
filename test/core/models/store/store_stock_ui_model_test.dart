import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/store/store_stock_ui_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // StoreAvailabilityState.fromJson
  // -------------------------------------------------------------------------

  group('StoreAvailabilityState.fromJson', () {
    test('parses isVisible', () {
      expect(
          StoreAvailabilityState.fromJson({'isVisible': false}).isVisible,
          isFalse);
    });

    test('isVisible defaults to true when absent', () {
      expect(StoreAvailabilityState.fromJson({}).isVisible, isTrue);
    });

    test('parses isPurchasable', () {
      expect(
          StoreAvailabilityState.fromJson({'isPurchasable': false})
              .isPurchasable,
          isFalse);
    });

    test('isPurchasable defaults to true when absent', () {
      expect(StoreAvailabilityState.fromJson({}).isPurchasable, isTrue);
    });

    test('parses requiresPremium', () {
      expect(
          StoreAvailabilityState.fromJson({'requiresPremium': true})
              .requiresPremium,
          isTrue);
    });

    test('requiresPremium defaults to false when absent', () {
      expect(StoreAvailabilityState.fromJson({}).requiresPremium, isFalse);
    });

    test('parses isFlashSale', () {
      expect(
          StoreAvailabilityState.fromJson({'isFlashSale': true}).isFlashSale,
          isTrue);
    });

    test('parses saleEndsAt', () {
      final s = StoreAvailabilityState.fromJson(
          {'saleEndsAt': '2025-12-01T00:00:00.000Z'});
      expect(s.saleEndsAt, isNotNull);
      expect(s.saleEndsAt!.month, 12);
    });

    test('saleEndsAt is null when absent', () {
      expect(StoreAvailabilityState.fromJson({}).saleEndsAt, isNull);
    });

    test('always constant has all defaults', () {
      expect(StoreAvailabilityState.always.isVisible, isTrue);
      expect(StoreAvailabilityState.always.isPurchasable, isTrue);
      expect(StoreAvailabilityState.always.requiresPremium, isFalse);
      expect(StoreAvailabilityState.always.isFlashSale, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // StoreStockState.fromJson
  // -------------------------------------------------------------------------

  group('StoreStockState.fromJson', () {
    test('parses policyType', () {
      expect(
          StoreStockState.fromJson({'policyType': 'per_user'}).policyType,
          'per_user');
    });

    test('policyType defaults to "unlimited" when absent', () {
      expect(StoreStockState.fromJson({}).policyType, 'unlimited');
    });

    test('parses maxQuantity', () {
      expect(StoreStockState.fromJson({'maxQuantity': 10}).maxQuantity, 10);
    });

    test('maxQuantity is null when absent', () {
      expect(StoreStockState.fromJson({}).maxQuantity, isNull);
    });

    test('parses usedQuantity', () {
      expect(
          StoreStockState.fromJson({'usedQuantity': 3}).usedQuantity, 3);
    });

    test('usedQuantity defaults to 0 when absent', () {
      expect(StoreStockState.fromJson({}).usedQuantity, 0);
    });

    test('parses remainingQuantity', () {
      expect(
          StoreStockState.fromJson({'remainingQuantity': 7}).remainingQuantity,
          7);
    });

    test('parses resetInterval', () {
      expect(
          StoreStockState.fromJson({'resetInterval': 'daily'}).resetInterval,
          'daily');
    });

    test('parses lastResetAt', () {
      final s = StoreStockState.fromJson(
          {'lastResetAt': '2025-06-01T00:00:00.000Z'});
      expect(s.lastResetAt, isNotNull);
    });

    test('parses nextResetAt', () {
      final s = StoreStockState.fromJson(
          {'nextResetAt': '2025-06-02T00:00:00.000Z'});
      expect(s.nextResetAt, isNotNull);
      expect(s.nextResetAt!.day, 2);
    });

    test('parses isSoldOut', () {
      expect(StoreStockState.fromJson({'isSoldOut': true}).isSoldOut, isTrue);
    });

    test('isSoldOut defaults to false when absent', () {
      expect(StoreStockState.fromJson({}).isSoldOut, isFalse);
    });

    test('parses isUnlimited', () {
      expect(
          StoreStockState.fromJson({'isUnlimited': false}).isUnlimited, isFalse);
    });

    test('isUnlimited defaults to true when absent', () {
      expect(StoreStockState.fromJson({}).isUnlimited, isTrue);
    });

    test('parses isOneTimePurchase', () {
      expect(
          StoreStockState.fromJson({'isOneTimePurchase': true})
              .isOneTimePurchase,
          isTrue);
    });

    test('parses expiresAt', () {
      final s =
          StoreStockState.fromJson({'expiresAt': '2025-08-01T00:00:00.000Z'});
      expect(s.expiresAt, isNotNull);
    });

    test('unlimited constant has default values', () {
      expect(StoreStockState.unlimited.policyType, 'unlimited');
      expect(StoreStockState.unlimited.isUnlimited, isTrue);
      expect(StoreStockState.unlimited.isSoldOut, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // StoreStockState — isExpired
  // -------------------------------------------------------------------------

  group('StoreStockState — isExpired', () {
    test('false when expiresAt is null', () {
      expect(StoreStockState.fromJson({}).isExpired, isFalse);
    });

    test('true when expiresAt is in the past', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final s = StoreStockState.fromJson({'expiresAt': past.toIso8601String()});
      expect(s.isExpired, isTrue);
    });

    test('false when expiresAt is in the future', () {
      final future = DateTime.now().toUtc().add(const Duration(days: 10));
      final s =
          StoreStockState.fromJson({'expiresAt': future.toIso8601String()});
      expect(s.isExpired, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // StoreStockState — hasUrgentStock
  // -------------------------------------------------------------------------

  group('StoreStockState — hasUrgentStock', () {
    test('false when isSoldOut', () {
      const s = StoreStockState(isSoldOut: true, isUnlimited: false);
      expect(s.hasUrgentStock, isFalse);
    });

    test('false when isUnlimited', () {
      const s = StoreStockState(isUnlimited: true);
      expect(s.hasUrgentStock, isFalse);
    });

    test('true when remainingQuantity is 1', () {
      const s = StoreStockState(
        remainingQuantity: 1,
        isUnlimited: false,
        isSoldOut: false,
      );
      expect(s.hasUrgentStock, isTrue);
    });

    test('true when nextResetAt is within 60 minutes', () {
      final soon = DateTime.now().toUtc().add(const Duration(minutes: 30));
      final s = StoreStockState(
        isUnlimited: false,
        isSoldOut: false,
        nextResetAt: soon,
      );
      expect(s.hasUrgentStock, isTrue);
    });

    test('false when reset is more than 60 minutes away', () {
      final later = DateTime.now().toUtc().add(const Duration(hours: 2));
      final s = StoreStockState(
        isUnlimited: false,
        isSoldOut: false,
        nextResetAt: later,
        remainingQuantity: 5,
      );
      expect(s.hasUrgentStock, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerStoreItem.fromJson — nested format
  // -------------------------------------------------------------------------

  group('PlayerStoreItem.fromJson — nested format', () {
    Map<String, dynamic> _json({
      String sku = 'power-up-hint',
      String title = 'Hint Pack',
      String description = '5 hints',
      String type = 'power_up',
      int price = 150,
      String currency = 'coins',
      Map<String, dynamic>? stock,
      Map<String, dynamic>? availability,
      String? iconPath,
      String? thumbnailUrl,
      bool owned = false,
      bool isFeatured = false,
    }) =>
        {
          'sku': sku,
          'title': title,
          'description': description,
          'type': type,
          'price': price,
          'currency': currency,
          if (stock != null) 'stock': stock,
          if (availability != null) 'availability': availability,
          if (iconPath != null) 'iconPath': iconPath,
          if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
          'owned': owned,
          'isFeatured': isFeatured,
        };

    test('parses sku', () {
      expect(PlayerStoreItem.fromJson(_json(sku: 'sku_x')).sku, 'sku_x');
    });

    test('parses sku from id fallback', () {
      final json = _json();
      json.remove('sku');
      json['id'] = 'id_fallback';
      expect(PlayerStoreItem.fromJson(json).sku, 'id_fallback');
    });

    test('parses title', () {
      expect(
          PlayerStoreItem.fromJson(_json(title: 'Shield Pack')).title,
          'Shield Pack');
    });

    test('parses title from name fallback', () {
      final json = _json();
      json.remove('title');
      json['name'] = 'Power Pack';
      expect(PlayerStoreItem.fromJson(json).title, 'Power Pack');
    });

    test('parses description', () {
      expect(
          PlayerStoreItem.fromJson(_json(description: 'Great item')).description,
          'Great item');
    });

    test('parses type', () {
      expect(PlayerStoreItem.fromJson(_json(type: 'cosmetic')).type, 'cosmetic');
    });

    test('parses type from itemType fallback', () {
      final json = _json();
      json.remove('type');
      json['itemType'] = 'power_up';
      expect(PlayerStoreItem.fromJson(json).type, 'power_up');
    });

    test('parses price', () {
      expect(PlayerStoreItem.fromJson(_json(price: 300)).price, 300);
    });

    test('parses priceCoins and sets currency to coins', () {
      final json = _json();
      json['priceCoins'] = 250;
      json.remove('price');
      final item = PlayerStoreItem.fromJson(json);
      expect(item.price, 250);
      expect(item.currency, 'coins');
    });

    test('parses currency', () {
      expect(
          PlayerStoreItem.fromJson(_json(currency: 'diamonds')).currency,
          'diamonds');
    });

    test('parses owned', () {
      expect(PlayerStoreItem.fromJson(_json(owned: true)).owned, isTrue);
    });

    test('owned defaults to false when absent', () {
      final json = _json();
      json.remove('owned');
      expect(PlayerStoreItem.fromJson(json).owned, isFalse);
    });

    test('parses isFeatured', () {
      expect(
          PlayerStoreItem.fromJson(_json(isFeatured: true)).isFeatured, isTrue);
    });

    test('parses iconPath', () {
      expect(
          PlayerStoreItem.fromJson(_json(iconPath: 'assets/icon.png')).iconPath,
          'assets/icon.png');
    });

    test('parses nested stock', () {
      final item = PlayerStoreItem.fromJson(_json(
        stock: {'isSoldOut': true, 'isUnlimited': false},
      ));
      expect(item.stock.isSoldOut, isTrue);
    });

    test('parses nested availability', () {
      final item = PlayerStoreItem.fromJson(_json(
        availability: {'isPurchasable': false},
      ));
      expect(item.availability.isPurchasable, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerStoreItem.fromJson — flat backend format
  // -------------------------------------------------------------------------

  group('PlayerStoreItem.fromJson — flat backend format', () {
    test('uses stockState "unlimited" → isUnlimited', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'item1',
        'name': 'Item',
        'description': '',
        'stockState': 'unlimited',
        'availabilityState': 'available',
        'priceCoins': 100,
      });
      expect(item.stock.isUnlimited, isTrue);
    });

    test('uses stockState "in_stock" → per_user policy', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'item2',
        'name': 'Item',
        'stockState': 'in_stock',
        'availabilityState': 'available',
        'priceCoins': 0,
      });
      expect(item.stock.policyType, 'per_user');
    });

    test('availabilityState "already_owned" → isPurchasable false', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'item3',
        'name': 'Item',
        'availabilityState': 'already_owned',
        'priceCoins': 0,
      });
      expect(item.availability.isPurchasable, isFalse);
    });

    test('discountPercent > 0 → isFlashSale true', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'item4',
        'name': 'Item',
        'availabilityState': 'available',
        'discountPercent': 20,
        'priceCoins': 100,
        'isAvailable': true,
      });
      expect(item.availability.isFlashSale, isTrue);
    });

    test('remainingQuantity -1 → isUnlimited true', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'item5',
        'name': 'Item',
        'remainingQuantity': -1,
        'priceCoins': 50,
      });
      expect(item.stock.isUnlimited, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerStoreItem — computed: isFree / canPurchase
  // -------------------------------------------------------------------------

  group('PlayerStoreItem — isFree', () {
    test('true when price is 0', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'free_item',
        'name': 'Free',
        'price': 0,
        'currency': 'coins',
      });
      expect(item.isFree, isTrue);
    });

    test('true when currency is "free"', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'free2',
        'name': 'Free2',
        'price': 1,
        'currency': 'free',
      });
      expect(item.isFree, isTrue);
    });

    test('false when price > 0 and currency is coins', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'paid',
        'name': 'Paid',
        'price': 100,
        'currency': 'coins',
      });
      expect(item.isFree, isFalse);
    });
  });

  group('PlayerStoreItem — canPurchase', () {
    test('false when not purchasable', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'x',
        'name': 'X',
        'availability': {'isPurchasable': false},
      });
      expect(item.canPurchase, isFalse);
    });

    test('false when sold out', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'x',
        'name': 'X',
        'stock': {'isSoldOut': true},
      });
      expect(item.canPurchase, isFalse);
    });

    test('false when stock expired', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final item = PlayerStoreItem.fromJson({
        'sku': 'x',
        'name': 'X',
        'stock': {'expiresAt': past.toIso8601String(), 'isUnlimited': false},
      });
      expect(item.canPurchase, isFalse);
    });

    test('false when one-time-purchase and already owned', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'x',
        'name': 'X',
        'owned': true,
        'stock': {'isOneTimePurchase': true},
      });
      expect(item.canPurchase, isFalse);
    });

    test('true for normal purchasable item', () {
      final item = PlayerStoreItem.fromJson({
        'sku': 'normal',
        'name': 'Normal',
        'price': 100,
        'currency': 'coins',
      });
      expect(item.canPurchase, isTrue);
    });
  });
}
