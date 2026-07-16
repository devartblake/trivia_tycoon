import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/store_item_model.dart';
import 'package:synaptix/game/models/currency_type.dart';

Map<String, dynamic> _baseJson({
  String id = 'item1',
  String? sku,
  String name = 'XP Booster',
  String description = 'Doubles XP for 30 min',
  String iconPath = 'assets/icons/xp.png',
  int price = 200,
  String currency = 'coins',
  String category = 'powerup',
  String? displayPriceLabel,
  bool requiresExternalCheckout = false,
  bool isLimited = false,
  bool isFeatured = false,
  int? duration,
  String? type,
  bool owned = false,
  int quantity = 1,
  int grantQuantity = 1,
  int maxPerPlayer = 0,
  String? mediaKey,
  int? sortOrder,
}) =>
    {
      'id': id,
      if (sku != null) 'sku': sku,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'price': price,
      'currency': currency,
      'category': category,
      if (displayPriceLabel != null) 'displayPriceLabel': displayPriceLabel,
      'requiresExternalCheckout': requiresExternalCheckout,
      'isLimited': isLimited,
      'isFeatured': isFeatured,
      if (duration != null) 'duration': duration,
      if (type != null) 'type': type,
      'owned': owned,
      'quantity': quantity,
      'grantQuantity': grantQuantity,
      'maxPerPlayer': maxPerPlayer,
      if (mediaKey != null) 'mediaKey': mediaKey,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

void main() {
  // -------------------------------------------------------------------------
  // StoreItemModel.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('StoreItemModel.fromJson — scalar fields', () {
    test('parses id', () {
      expect(StoreItemModel.fromJson(_baseJson(id: 'i99')).id, 'i99');
    });

    test('parses sku', () {
      expect(StoreItemModel.fromJson(_baseJson(sku: 'SKU_ABC')).sku, 'SKU_ABC');
    });

    test('sku is null when absent', () {
      expect(StoreItemModel.fromJson(_baseJson()).sku, isNull);
    });

    test('parses name', () {
      expect(StoreItemModel.fromJson(_baseJson(name: 'Dragon Skin')).name,
          'Dragon Skin');
    });

    test('parses description', () {
      expect(
          StoreItemModel.fromJson(_baseJson(description: 'A cool skin'))
              .description,
          'A cool skin');
    });

    test('description defaults to "" when absent', () {
      final json = _baseJson();
      json.remove('description');
      expect(StoreItemModel.fromJson(json).description, '');
    });

    test('parses iconPath', () {
      expect(
          StoreItemModel.fromJson(_baseJson(iconPath: 'assets/skin.png'))
              .iconPath,
          'assets/skin.png');
    });

    test('iconPath defaults to "" when absent', () {
      final json = _baseJson();
      json.remove('iconPath');
      expect(StoreItemModel.fromJson(json).iconPath, '');
    });

    test('parses price as int', () {
      expect(StoreItemModel.fromJson(_baseJson(price: 500)).price, 500);
    });

    test('parses price as num (rounds)', () {
      final json = _baseJson();
      json['price'] = 99.9;
      expect(StoreItemModel.fromJson(json).price, 100);
    });

    test('parses currency', () {
      expect(StoreItemModel.fromJson(_baseJson(currency: 'diamonds')).currency,
          'diamonds');
    });

    test('parses category', () {
      expect(StoreItemModel.fromJson(_baseJson(category: 'avatar')).category,
          'avatar');
    });

    test('parses displayPriceLabel', () {
      expect(
          StoreItemModel.fromJson(_baseJson(displayPriceLabel: '200 coins'))
              .displayPriceLabel,
          '200 coins');
    });

    test('displayPriceLabel is null when absent', () {
      expect(StoreItemModel.fromJson(_baseJson()).displayPriceLabel, isNull);
    });

    test('parses requiresExternalCheckout true', () {
      expect(
          StoreItemModel.fromJson(_baseJson(requiresExternalCheckout: true))
              .requiresExternalCheckout,
          isTrue);
    });

    test('requiresExternalCheckout defaults to false', () {
      expect(StoreItemModel.fromJson(_baseJson()).requiresExternalCheckout,
          isFalse);
    });

    test('parses isLimited', () {
      expect(StoreItemModel.fromJson(_baseJson(isLimited: true)).isLimited,
          isTrue);
    });

    test('parses isFeatured', () {
      expect(StoreItemModel.fromJson(_baseJson(isFeatured: true)).isFeatured,
          isTrue);
    });

    test('parses duration', () {
      expect(StoreItemModel.fromJson(_baseJson(duration: 1800)).duration, 1800);
    });

    test('duration is null when absent', () {
      expect(StoreItemModel.fromJson(_baseJson()).duration, isNull);
    });

    test('parses type', () {
      expect(StoreItemModel.fromJson(_baseJson(type: 'consumable')).type,
          'consumable');
    });

    test('parses owned', () {
      expect(StoreItemModel.fromJson(_baseJson(owned: true)).owned, isTrue);
    });

    test('owned defaults to false when absent', () {
      final json = _baseJson();
      json.remove('owned');
      expect(StoreItemModel.fromJson(json).owned, isFalse);
    });

    test('parses quantity', () {
      expect(StoreItemModel.fromJson(_baseJson(quantity: 5)).quantity, 5);
    });

    test('quantity defaults to 1 when absent', () {
      final json = _baseJson();
      json.remove('quantity');
      expect(StoreItemModel.fromJson(json).quantity, 1);
    });

    test('parses grantQuantity', () {
      expect(StoreItemModel.fromJson(_baseJson(grantQuantity: 3)).grantQuantity,
          3);
    });

    test('parses maxPerPlayer', () {
      expect(StoreItemModel.fromJson(_baseJson(maxPerPlayer: 10)).maxPerPlayer,
          10);
    });

    test('parses mediaKey', () {
      expect(StoreItemModel.fromJson(_baseJson(mediaKey: 'mk_001')).mediaKey,
          'mk_001');
    });

    test('parses sortOrder', () {
      expect(StoreItemModel.fromJson(_baseJson(sortOrder: 7)).sortOrder, 7);
    });

    test('sortOrder is null when absent', () {
      expect(StoreItemModel.fromJson(_baseJson()).sortOrder, isNull);
    });

    test('sortOrder is null when not int', () {
      final json = _baseJson();
      json['sortOrder'] = 'first';
      expect(StoreItemModel.fromJson(json).sortOrder, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // StoreItemModel — currencyType
  // -------------------------------------------------------------------------

  group('StoreItemModel — currencyType', () {
    test('coins → CurrencyType.coins', () {
      expect(StoreItemModel.fromJson(_baseJson(currency: 'coins')).currencyType,
          CurrencyType.coins);
    });

    test('diamonds → CurrencyType.diamonds', () {
      expect(
          StoreItemModel.fromJson(_baseJson(currency: 'diamonds')).currencyType,
          CurrencyType.diamonds);
    });

    test('unknown currency → CurrencyType.coins (default)', () {
      expect(StoreItemModel.fromJson(_baseJson(currency: 'usd')).currencyType,
          CurrencyType.coins);
    });

    test('case-insensitive: DIAMONDS → diamonds', () {
      expect(
          StoreItemModel.fromJson(_baseJson(currency: 'DIAMONDS')).currencyType,
          CurrencyType.diamonds);
    });
  });

  // -------------------------------------------------------------------------
  // StoreItemModel.fromStoreCatalog
  // -------------------------------------------------------------------------

  group('StoreItemModel.fromStoreCatalog — price mapping', () {
    test('priceCoins > 0 → price and currency=coins', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'priceCoins': 300});
      expect(item.price, 300);
      expect(item.currency, 'coins');
    });

    test('priceDiamonds > 0 (no priceCoins) → price and currency=diamonds', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'priceDiamonds': 50});
      expect(item.price, 50);
      expect(item.currency, 'diamonds');
    });

    test('priceCoins takes precedence over priceDiamonds', () {
      final item = StoreItemModel.fromStoreCatalog(
          {'id': 's1', 'priceCoins': 100, 'priceDiamonds': 20});
      expect(item.price, 100);
      expect(item.currency, 'coins');
    });

    test(
        'both zero + no displayItem → currency=usd, price=0, externalCheckout=true',
        () {
      final item = StoreItemModel.fromStoreCatalog({'id': 's1'});
      expect(item.currency, 'usd');
      expect(item.price, 0);
      expect(item.requiresExternalCheckout, isTrue);
    });

    test('both zero + displayItem with price → uses displayItem price', () {
      final display =
          StoreItemModel.fromJson(_baseJson(price: 999, currency: 'coins'));
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1'}, displayItem: display);
      expect(item.price, 999);
      expect(item.currency, 'coins');
    });

    test('requiresExternalCheckout true in json overrides', () {
      final item = StoreItemModel.fromStoreCatalog(
          {'id': 's1', 'priceCoins': 100, 'requiresExternalCheckout': true});
      expect(item.requiresExternalCheckout, isTrue);
    });
  });

  group('StoreItemModel.fromStoreCatalog — id / name resolution', () {
    test('id from id field', () {
      final item = StoreItemModel.fromStoreCatalog({'id': 'cat_id'});
      expect(item.id, 'cat_id');
    });

    test('id falls back to sku when id absent', () {
      final item = StoreItemModel.fromStoreCatalog({'sku': 'SKU_001'});
      expect(item.id, 'SKU_001');
    });

    test('name from json', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'name': 'Rocket Pack'});
      expect(item.name, 'Rocket Pack');
    });

    test('name falls back to displayItem.name', () {
      final display = StoreItemModel.fromJson(_baseJson(name: 'Display Name'));
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1'}, displayItem: display);
      expect(item.name, 'Display Name');
    });

    test('name defaults to "Store Item" when all absent', () {
      final item = StoreItemModel.fromStoreCatalog({'id': 's1'});
      expect(item.name, 'Store Item');
    });
  });

  group('StoreItemModel.fromStoreCatalog — category and iconPath', () {
    test('category from itemType', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'itemType': 'avatar'});
      expect(item.category, 'avatar');
    });

    test('default icon for powerup category', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'itemType': 'powerup'});
      expect(item.iconPath, contains('power-up'));
    });

    test('default icon for avatar category', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'itemType': 'avatar'});
      expect(item.iconPath, contains('avatar'));
    });

    test('default icon for theme category', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'itemType': 'theme'});
      expect(item.iconPath, contains('theme'));
    });

    test('default icon for currency category', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'itemType': 'currency'});
      expect(item.iconPath, contains('coins'));
    });

    test('displayItem iconPath takes precedence', () {
      final display =
          StoreItemModel.fromJson(_baseJson(iconPath: 'assets/custom.png'));
      final item = StoreItemModel.fromStoreCatalog(
          {'id': 's1', 'itemType': 'avatar'},
          displayItem: display);
      expect(item.iconPath, 'assets/custom.png');
    });
  });

  group('StoreItemModel.fromStoreCatalog — grantQuantity/maxPerPlayer', () {
    test('parses grantQuantity from json', () {
      final item = StoreItemModel.fromStoreCatalog(
          {'id': 's1', 'priceCoins': 100, 'grantQuantity': 5});
      expect(item.grantQuantity, 5);
    });

    test('grantQuantity defaults to 1', () {
      final item = StoreItemModel.fromStoreCatalog({'id': 's1'});
      expect(item.grantQuantity, 1);
    });

    test('parses maxPerPlayer', () {
      final item =
          StoreItemModel.fromStoreCatalog({'id': 's1', 'maxPerPlayer': 3});
      expect(item.maxPerPlayer, 3);
    });

    test('owned from parameter', () {
      final item = StoreItemModel.fromStoreCatalog({'id': 's1'}, owned: true);
      expect(item.owned, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // StoreItemModel.toJson
  // -------------------------------------------------------------------------

  group('StoreItemModel.toJson', () {
    test('serializes all basic fields', () {
      final item = StoreItemModel.fromJson(_baseJson());
      final json = item.toJson();
      expect(json['id'], item.id);
      expect(json['name'], item.name);
      expect(json['price'], item.price);
      expect(json['currency'], item.currency);
      expect(json['category'], item.category);
    });

    test('duration present in toJson when set', () {
      final item = StoreItemModel.fromJson(_baseJson(duration: 3600));
      expect(item.toJson().containsKey('duration'), isTrue);
      expect(item.toJson()['duration'], 3600);
    });

    test('duration absent from toJson when null', () {
      final item = StoreItemModel.fromJson(_baseJson());
      expect(item.toJson().containsKey('duration'), isFalse);
    });

    test('round-trip preserves name, price, currency', () {
      final original = StoreItemModel.fromJson(
          _baseJson(name: 'Gem Pack', price: 50, currency: 'diamonds'));
      final restored = StoreItemModel.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.price, original.price);
      expect(restored.currency, original.currency);
    });
  });
}
