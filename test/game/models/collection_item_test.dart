import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/collection_item.dart';

Map<String, dynamic> _baseJson({
  String id = 'ci1',
  String name = 'Dragon Scale',
  String category = 'mythology',
  String rarity = 'epic',
  String description = 'A shimmering scale',
  String aiImagePrompt = 'dragon scale glowing',
  int pointValue = 150,
  bool isUnlocked = false,
  String? unlockedAt,
  String? iconPath,
}) =>
    {
      'id': id,
      'name': name,
      'category': category,
      'rarity': rarity,
      'description': description,
      'aiImagePrompt': aiImagePrompt,
      'pointValue': pointValue,
      'isUnlocked': isUnlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt,
      if (iconPath != null) 'iconPath': iconPath,
    };

void main() {
  // -------------------------------------------------------------------------
  // CollectionItem.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('CollectionItem.fromJson — scalar fields', () {
    test('parses id', () {
      expect(CollectionItem.fromJson(_baseJson(id: 'ci99')).id, 'ci99');
    });

    test('parses name', () {
      expect(CollectionItem.fromJson(_baseJson(name: 'Phoenix Feather')).name,
          'Phoenix Feather');
    });

    test('parses category', () {
      expect(CollectionItem.fromJson(_baseJson(category: 'science')).category,
          'science');
    });

    test('parses rarity', () {
      expect(CollectionItem.fromJson(_baseJson(rarity: 'legendary')).rarity,
          'legendary');
    });

    test('parses description', () {
      expect(
          CollectionItem.fromJson(_baseJson(description: 'Rare find'))
              .description,
          'Rare find');
    });

    test('parses aiImagePrompt', () {
      expect(
          CollectionItem.fromJson(_baseJson(aiImagePrompt: 'glowing orb'))
              .aiImagePrompt,
          'glowing orb');
    });

    test('parses pointValue', () {
      expect(
          CollectionItem.fromJson(_baseJson(pointValue: 500)).pointValue, 500);
    });

    test('parses isUnlocked true', () {
      expect(CollectionItem.fromJson(_baseJson(isUnlocked: true)).isUnlocked,
          isTrue);
    });

    test('isUnlocked defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isUnlocked');
      expect(CollectionItem.fromJson(json).isUnlocked, isFalse);
    });

    test('parses iconPath', () {
      expect(
          CollectionItem.fromJson(_baseJson(iconPath: 'assets/img/ci1.png'))
              .iconPath,
          'assets/img/ci1.png');
    });

    test('iconPath is null when absent', () {
      expect(CollectionItem.fromJson(_baseJson()).iconPath, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem.fromJson — DateTime
  // -------------------------------------------------------------------------

  group('CollectionItem.fromJson — unlockedAt', () {
    test('parses unlockedAt', () {
      final item = CollectionItem.fromJson(
          _baseJson(unlockedAt: '2025-04-10T12:00:00.000Z'));
      expect(item.unlockedAt, isNotNull);
      expect(item.unlockedAt!.month, 4);
    });

    test('unlockedAt is null when absent', () {
      expect(CollectionItem.fromJson(_baseJson()).unlockedAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem — rarityColor
  // -------------------------------------------------------------------------

  group('CollectionItem — rarityColor', () {
    test('legendary → gold', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'legendary')).rarityColor,
          '#FFD700');
    });

    test('epic → purple', () {
      expect(CollectionItem.fromJson(_baseJson(rarity: 'epic')).rarityColor,
          '#A335EE');
    });

    test('rare → blue', () {
      expect(CollectionItem.fromJson(_baseJson(rarity: 'rare')).rarityColor,
          '#0070DD');
    });

    test('uncommon → green', () {
      expect(CollectionItem.fromJson(_baseJson(rarity: 'uncommon')).rarityColor,
          '#1EFF00');
    });

    test('common → gray', () {
      expect(CollectionItem.fromJson(_baseJson(rarity: 'common')).rarityColor,
          '#9D9D9D');
    });

    test('unknown rarity → gray (default)', () {
      expect(CollectionItem.fromJson(_baseJson(rarity: 'mythical')).rarityColor,
          '#9D9D9D');
    });

    test('case-insensitive: LEGENDARY → gold', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'LEGENDARY')).rarityColor,
          '#FFD700');
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem — rarityWeight
  // -------------------------------------------------------------------------

  group('CollectionItem — rarityWeight', () {
    test('legendary = 5', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'legendary')).rarityWeight,
          5);
    });

    test('epic = 4', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'epic')).rarityWeight, 4);
    });

    test('rare = 3', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'rare')).rarityWeight, 3);
    });

    test('uncommon = 2', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'uncommon')).rarityWeight,
          2);
    });

    test('common = 1', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'common')).rarityWeight, 1);
    });

    test('unknown rarity = 1 (default)', () {
      expect(
          CollectionItem.fromJson(_baseJson(rarity: 'super')).rarityWeight, 1);
    });

    test('rarityWeight enables comparison: legendary > epic', () {
      final legendary =
          CollectionItem.fromJson(_baseJson(rarity: 'legendary')).rarityWeight;
      final epic =
          CollectionItem.fromJson(_baseJson(rarity: 'epic')).rarityWeight;
      expect(legendary, greaterThan(epic));
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem — unlock()
  // -------------------------------------------------------------------------

  group('CollectionItem — unlock()', () {
    test('sets isUnlocked to true', () {
      final item = CollectionItem.fromJson(_baseJson());
      expect(item.unlock().isUnlocked, isTrue);
    });

    test('sets unlockedAt when previously null', () {
      final item = CollectionItem.fromJson(_baseJson());
      final unlocked = item.unlock();
      expect(unlocked.unlockedAt, isNotNull);
    });

    test('preserves existing unlockedAt when already set', () {
      final item = CollectionItem.fromJson(
          _baseJson(unlockedAt: '2025-01-01T00:00:00.000Z'));
      final unlocked = item.unlock();
      expect(unlocked.unlockedAt!.year, 2025);
      expect(unlocked.unlockedAt!.month, 1);
    });

    test('preserves all other fields', () {
      final item = CollectionItem.fromJson(
          _baseJson(name: 'Orb', pointValue: 999, iconPath: 'assets/orb.png'));
      final unlocked = item.unlock();
      expect(unlocked.name, 'Orb');
      expect(unlocked.pointValue, 999);
      expect(unlocked.iconPath, 'assets/orb.png');
    });

    test('calling unlock twice preserves first unlockedAt', () {
      final item = CollectionItem.fromJson(_baseJson());
      final first = item.unlock();
      final second = first.unlock();
      expect(second.unlockedAt, first.unlockedAt);
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem.toJson
  // -------------------------------------------------------------------------

  group('CollectionItem.toJson', () {
    test('serializes all scalar fields', () {
      final item = CollectionItem.fromJson(_baseJson());
      final json = item.toJson();
      expect(json['id'], item.id);
      expect(json['name'], item.name);
      expect(json['category'], item.category);
      expect(json['rarity'], item.rarity);
      expect(json['description'], item.description);
      expect(json['aiImagePrompt'], item.aiImagePrompt);
      expect(json['pointValue'], item.pointValue);
      expect(json['isUnlocked'], item.isUnlocked);
    });

    test('serializes unlockedAt as ISO string when set', () {
      final item = CollectionItem.fromJson(
          _baseJson(unlockedAt: '2025-05-20T00:00:00.000Z'));
      expect(item.toJson()['unlockedAt'], isA<String>());
    });

    test('unlockedAt is null in toJson when absent', () {
      expect(
          CollectionItem.fromJson(_baseJson()).toJson()['unlockedAt'], isNull);
    });

    test('round-trip preserves all fields', () {
      final original = CollectionItem.fromJson(_baseJson(
        name: 'Crystal Shard',
        rarity: 'rare',
        pointValue: 300,
        isUnlocked: true,
        unlockedAt: '2025-03-01T00:00:00.000Z',
        iconPath: 'assets/crystal.png',
      ));
      final restored = CollectionItem.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.rarity, original.rarity);
      expect(restored.pointValue, original.pointValue);
      expect(restored.isUnlocked, original.isUnlocked);
      expect(restored.iconPath, original.iconPath);
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem.copyWith
  // -------------------------------------------------------------------------

  group('CollectionItem.copyWith', () {
    late CollectionItem base;
    setUp(() => base = CollectionItem.fromJson(_baseJson()));

    test('copies name', () {
      expect(base.copyWith(name: 'Starstone').name, 'Starstone');
    });

    test('copies rarity', () {
      expect(base.copyWith(rarity: 'legendary').rarity, 'legendary');
    });

    test('copies pointValue', () {
      expect(base.copyWith(pointValue: 750).pointValue, 750);
    });

    test('copies isUnlocked', () {
      expect(base.copyWith(isUnlocked: true).isUnlocked, isTrue);
    });

    test('copies iconPath', () {
      expect(
          base.copyWith(iconPath: 'assets/new.png').iconPath, 'assets/new.png');
    });

    test('copies category', () {
      expect(base.copyWith(category: 'history').category, 'history');
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(rarity: 'rare');
      expect(updated.id, base.id);
      expect(updated.name, base.name);
      expect(updated.pointValue, base.pointValue);
    });
  });

  // -------------------------------------------------------------------------
  // CollectionItem equality
  // -------------------------------------------------------------------------

  group('CollectionItem — equality', () {
    test('equal items with same fields', () {
      final a = CollectionItem.fromJson(_baseJson());
      final b = CollectionItem.fromJson(_baseJson());
      expect(a, equals(b));
    });

    test('not equal when id differs', () {
      final a = CollectionItem.fromJson(_baseJson(id: 'ci1'));
      final b = CollectionItem.fromJson(_baseJson(id: 'ci2'));
      expect(a, isNot(equals(b)));
    });

    test('not equal when isUnlocked differs', () {
      final a = CollectionItem.fromJson(_baseJson(isUnlocked: false));
      final b = CollectionItem.fromJson(_baseJson(isUnlocked: true));
      expect(a, isNot(equals(b)));
    });

    test('not equal when pointValue differs', () {
      final a = CollectionItem.fromJson(_baseJson(pointValue: 100));
      final b = CollectionItem.fromJson(_baseJson(pointValue: 200));
      expect(a, isNot(equals(b)));
    });

    test('hashCode equal for equal objects', () {
      final a = CollectionItem.fromJson(_baseJson());
      final b = CollectionItem.fromJson(_baseJson());
      expect(a.hashCode, b.hashCode);
    });
  });
}
