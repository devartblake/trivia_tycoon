import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/utils/sample_store_data.dart';

void main() {
  // -------------------------------------------------------------------------
  // SampleStoreData — list length
  // -------------------------------------------------------------------------

  group('SampleStoreData — list length', () {
    test('sampleStoreItems contains exactly 3 items', () {
      expect(SampleStoreData().sampleStoreItems.length, 3);
    });

    test('two instances both have 3 items', () {
      expect(SampleStoreData().sampleStoreItems.length, 3);
      expect(SampleStoreData().sampleStoreItems.length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // SampleStoreData — item[0]: avatar_fox
  // -------------------------------------------------------------------------

  group('SampleStoreData — item 0 (avatar_fox)', () {
    final item = SampleStoreData().sampleStoreItems[0];

    test('id is "avatar_fox"', () {
      expect(item.id, 'avatar_fox');
    });

    test('name is "Fox Avatar"', () {
      expect(item.name, 'Fox Avatar');
    });

    test('price is 200', () {
      expect(item.price, 200);
    });

    test('currency is "coins"', () {
      expect(item.currency, 'coins');
    });

    test('category is "avatar"', () {
      expect(item.category, 'avatar');
    });

    test('iconPath is non-empty', () {
      expect(item.iconPath, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SampleStoreData — item[1]: theme_dark
  // -------------------------------------------------------------------------

  group('SampleStoreData — item 1 (theme_dark)', () {
    final item = SampleStoreData().sampleStoreItems[1];

    test('id is "theme_dark"', () {
      expect(item.id, 'theme_dark');
    });

    test('price is 350', () {
      expect(item.price, 350);
    });

    test('currency is "diamonds"', () {
      expect(item.currency, 'diamonds');
    });

    test('category is "theme"', () {
      expect(item.category, 'theme');
    });

    test('iconPath is non-empty', () {
      expect(item.iconPath, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SampleStoreData — item[2]: power_hint
  // -------------------------------------------------------------------------

  group('SampleStoreData — item 2 (power_hint)', () {
    final item = SampleStoreData().sampleStoreItems[2];

    test('id is "power_hint"', () {
      expect(item.id, 'power_hint');
    });

    test('price is 100', () {
      expect(item.price, 100);
    });

    test('currency is "coins"', () {
      expect(item.currency, 'coins');
    });

    test('category is "power-up"', () {
      expect(item.category, 'power-up');
    });

    test('iconPath is non-empty', () {
      expect(item.iconPath, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // SampleStoreData — all items
  // -------------------------------------------------------------------------

  group('SampleStoreData — all items', () {
    test('all items have non-empty ids', () {
      for (final item in SampleStoreData().sampleStoreItems) {
        expect(item.id, isNotEmpty, reason: 'item id should not be empty');
      }
    });

    test('all items have non-empty descriptions', () {
      for (final item in SampleStoreData().sampleStoreItems) {
        expect(item.description, isNotEmpty);
      }
    });

    test('all item ids are unique', () {
      final ids = SampleStoreData().sampleStoreItems.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
