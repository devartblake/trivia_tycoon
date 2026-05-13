import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/reward_step_models.dart';

Map<String, dynamic> _baseJson({
  double pointValue = 500.0,
  int quantity = 1,
  String description = 'Bonus coins',
  String type = 'coins',
  String? imageUrl,
  bool isLocked = false,
  String? unlockDate,
  Map<String, dynamic>? metadata,
}) =>
    {
      'pointValue': pointValue,
      'quantity': quantity,
      'description': description,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isLocked': isLocked,
      if (unlockDate != null) 'unlockDate': unlockDate,
      if (metadata != null) 'metadata': metadata,
    };

void main() {
  // -------------------------------------------------------------------------
  // RewardType — displayName
  // -------------------------------------------------------------------------

  group('RewardType — displayName', () {
    test('coins → "Coins"', () {
      expect(RewardType.coins.displayName, 'Coins');
    });

    test('gems → "Gems"', () {
      expect(RewardType.gems.displayName, 'Gems');
    });

    test('powerUp → "Power-Up"', () {
      expect(RewardType.powerUp.displayName, 'Power-Up');
    });

    test('badge → "Badge"', () {
      expect(RewardType.badge.displayName, 'Badge');
    });

    test('avatar → "Avatar"', () {
      expect(RewardType.avatar.displayName, 'Avatar');
    });

    test('theme → "Theme"', () {
      expect(RewardType.theme.displayName, 'Theme');
    });

    test('mysteryBox → "Mystery Box"', () {
      expect(RewardType.mysteryBox.displayName, 'Mystery Box');
    });

    test('giftCard → "Gift Card"', () {
      expect(RewardType.giftCard.displayName, 'Gift Card');
    });

    test('premiumAccess → "Premium Access"', () {
      expect(RewardType.premiumAccess.displayName, 'Premium Access');
    });

    test('xpBoost → "XP Boost"', () {
      expect(RewardType.xpBoost.displayName, 'XP Boost');
    });

    test('custom → "Reward"', () {
      expect(RewardType.custom.displayName, 'Reward');
    });
  });

  // -------------------------------------------------------------------------
  // RewardType — defaultIcon
  // -------------------------------------------------------------------------

  group('RewardType — defaultIcon', () {
    test('coins → monetization_on', () {
      expect(RewardType.coins.defaultIcon, Icons.monetization_on);
    });

    test('gems → diamond', () {
      expect(RewardType.gems.defaultIcon, Icons.diamond);
    });

    test('powerUp → flash_on', () {
      expect(RewardType.powerUp.defaultIcon, Icons.flash_on);
    });

    test('badge → military_tech', () {
      expect(RewardType.badge.defaultIcon, Icons.military_tech);
    });

    test('avatar → face', () {
      expect(RewardType.avatar.defaultIcon, Icons.face);
    });

    test('theme → palette', () {
      expect(RewardType.theme.defaultIcon, Icons.palette);
    });

    test('mysteryBox → inventory_2', () {
      expect(RewardType.mysteryBox.defaultIcon, Icons.inventory_2);
    });

    test('giftCard → card_giftcard', () {
      expect(RewardType.giftCard.defaultIcon, Icons.card_giftcard);
    });

    test('premiumAccess → stars', () {
      expect(RewardType.premiumAccess.defaultIcon, Icons.stars);
    });

    test('xpBoost → trending_up', () {
      expect(RewardType.xpBoost.defaultIcon, Icons.trending_up);
    });

    test('custom → redeem', () {
      expect(RewardType.custom.defaultIcon, Icons.redeem);
    });
  });

  // -------------------------------------------------------------------------
  // RewardType — defaultColor
  // -------------------------------------------------------------------------

  group('RewardType — defaultColor', () {
    test('coins → 0xFFFFA500', () {
      expect(RewardType.coins.defaultColor, const Color(0xFFFFA500));
    });

    test('gems → 0xFF9C27B0', () {
      expect(RewardType.gems.defaultColor, const Color(0xFF9C27B0));
    });

    test('powerUp → 0xFF2196F3', () {
      expect(RewardType.powerUp.defaultColor, const Color(0xFF2196F3));
    });

    test('badge → 0xFFF44336', () {
      expect(RewardType.badge.defaultColor, const Color(0xFFF44336));
    });

    test('avatar → 0xFF4CAF50', () {
      expect(RewardType.avatar.defaultColor, const Color(0xFF4CAF50));
    });

    test('theme → 0xFFE91E63', () {
      expect(RewardType.theme.defaultColor, const Color(0xFFE91E63));
    });

    test('mysteryBox → 0xFF795548', () {
      expect(RewardType.mysteryBox.defaultColor, const Color(0xFF795548));
    });

    test('giftCard → 0xFFFF9800', () {
      expect(RewardType.giftCard.defaultColor, const Color(0xFFFF9800));
    });

    test('premiumAccess → 0xFFFFD700', () {
      expect(RewardType.premiumAccess.defaultColor, const Color(0xFFFFD700));
    });

    test('xpBoost → 0xFF00BCD4', () {
      expect(RewardType.xpBoost.defaultColor, const Color(0xFF00BCD4));
    });

    test('custom → 0xFF607D8B', () {
      expect(RewardType.custom.defaultColor, const Color(0xFF607D8B));
    });
  });

  // -------------------------------------------------------------------------
  // RewardStep.fromJson
  // -------------------------------------------------------------------------

  group('RewardStep.fromJson — scalar fields', () {
    test('parses pointValue', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 250.0));
      expect(r.pointValue, 250.0);
    });

    test('parses pointValue as int from JSON', () {
      final json = _baseJson();
      json['pointValue'] = 100; // int, not double
      final r = RewardStep.fromJson(json);
      expect(r.pointValue, 100.0);
    });

    test('parses quantity', () {
      final r = RewardStep.fromJson(_baseJson(quantity: 5));
      expect(r.quantity, 5);
    });

    test('quantity defaults to 1 when absent', () {
      final json = _baseJson();
      json.remove('quantity');
      expect(RewardStep.fromJson(json).quantity, 1);
    });

    test('parses description', () {
      final r = RewardStep.fromJson(_baseJson(description: 'Free gems'));
      expect(r.description, 'Free gems');
    });

    test('description defaults to "" when absent', () {
      final json = _baseJson();
      json.remove('description');
      expect(RewardStep.fromJson(json).description, '');
    });

    test('parses imageUrl', () {
      final r = RewardStep.fromJson(
          _baseJson(imageUrl: 'https://img.test/reward.png'));
      expect(r.imageUrl, 'https://img.test/reward.png');
    });

    test('imageUrl is null when absent', () {
      expect(RewardStep.fromJson(_baseJson()).imageUrl, isNull);
    });

    test('parses isLocked', () {
      final r = RewardStep.fromJson(_baseJson(isLocked: true));
      expect(r.isLocked, isTrue);
    });

    test('isLocked defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isLocked');
      expect(RewardStep.fromJson(json).isLocked, isFalse);
    });

    test('parses unlockDate', () {
      final r = RewardStep.fromJson(
          _baseJson(unlockDate: '2025-12-01T00:00:00.000Z'));
      expect(r.unlockDate, isNotNull);
      expect(r.unlockDate!.month, 12);
    });

    test('unlockDate is null when absent', () {
      expect(RewardStep.fromJson(_baseJson()).unlockDate, isNull);
    });

    test('parses metadata', () {
      final r =
          RewardStep.fromJson(_baseJson(metadata: {'bonus': true, 'tier': 2}));
      expect(r.metadata!['tier'], 2);
    });

    test('metadata is null when absent', () {
      expect(RewardStep.fromJson(_baseJson()).metadata, isNull);
    });
  });

  group('RewardStep.fromJson — type parsing', () {
    for (final t in RewardType.values) {
      test('parses type ${t.name}', () {
        final r = RewardStep.fromJson(_baseJson(type: t.name));
        expect(r.type, t);
      });
    }

    test('unknown type falls back to coins', () {
      final r = RewardStep.fromJson(_baseJson(type: 'loot_box'));
      expect(r.type, RewardType.coins);
    });
  });

  // -------------------------------------------------------------------------
  // RewardStep — isUnlocked
  // -------------------------------------------------------------------------

  group('RewardStep — isUnlocked', () {
    test('true when not locked and no unlockDate', () {
      final r = RewardStep.fromJson(_baseJson(isLocked: false));
      expect(r.isUnlocked, isTrue);
    });

    test('false when isLocked is true', () {
      final r = RewardStep.fromJson(_baseJson(isLocked: true));
      expect(r.isUnlocked, isFalse);
    });

    test('false when unlockDate is in the future', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final r = RewardStep.fromJson(
          _baseJson(unlockDate: future.toIso8601String()));
      expect(r.isUnlocked, isFalse);
    });

    test('true when unlockDate is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final r = RewardStep.fromJson(
          _baseJson(unlockDate: past.toIso8601String()));
      expect(r.isUnlocked, isTrue);
    });

    test('false when locked AND unlockDate in past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final r = RewardStep.fromJson(
          _baseJson(isLocked: true, unlockDate: past.toIso8601String()));
      expect(r.isUnlocked, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // RewardStep — displayText
  // -------------------------------------------------------------------------

  group('RewardStep — displayText', () {
    test('returns description when quantity is 1', () {
      final r = RewardStep.fromJson(_baseJson(description: 'Gold coin', quantity: 1));
      expect(r.displayText, 'Gold coin');
    });

    test('appends x{quantity} when quantity > 1', () {
      final r = RewardStep.fromJson(_baseJson(description: 'Gold coin', quantity: 3));
      expect(r.displayText, 'Gold coin x3');
    });

    test('appends large quantity', () {
      final r = RewardStep.fromJson(
          _baseJson(description: 'Gems', quantity: 100));
      expect(r.displayText, 'Gems x100');
    });
  });

  // -------------------------------------------------------------------------
  // RewardStep — formattedPoints
  // -------------------------------------------------------------------------

  group('RewardStep — formattedPoints', () {
    test('returns plain number when < 1000', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 500.0));
      expect(r.formattedPoints, '500');
    });

    test('returns plain number for exactly 999', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 999.0));
      expect(r.formattedPoints, '999');
    });

    test('uses k suffix for 1000', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 1000.0));
      expect(r.formattedPoints, '1.0k');
    });

    test('uses k suffix for 1500', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 1500.0));
      expect(r.formattedPoints, '1.5k');
    });

    test('uses k suffix for 10000', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 10000.0));
      expect(r.formattedPoints, '10.0k');
    });
  });

  // -------------------------------------------------------------------------
  // RewardStep.toJson
  // -------------------------------------------------------------------------

  group('RewardStep.toJson', () {
    test('serializes type as name string', () {
      final r = RewardStep.fromJson(_baseJson(type: 'gems'));
      expect(r.toJson()['type'], 'gems');
    });

    test('serializes pointValue', () {
      final r = RewardStep.fromJson(_baseJson(pointValue: 750.0));
      expect(r.toJson()['pointValue'], 750.0);
    });

    test('serializes unlockDate as ISO string when present', () {
      final r = RewardStep.fromJson(
          _baseJson(unlockDate: '2025-12-01T00:00:00.000Z'));
      expect(r.toJson()['unlockDate'], isA<String>());
    });

    test('unlockDate is null in JSON when absent', () {
      expect(RewardStep.fromJson(_baseJson()).toJson()['unlockDate'], isNull);
    });

    test('round-trip preserves type', () {
      final r = RewardStep.fromJson(_baseJson(type: 'badge'));
      final restored = RewardStep.fromJson(r.toJson());
      expect(restored.type, RewardType.badge);
    });
  });

  // -------------------------------------------------------------------------
  // RewardStep.copyWith
  // -------------------------------------------------------------------------

  group('RewardStep.copyWith', () {
    late RewardStep base;
    setUp(() => base = RewardStep.fromJson(_baseJson()));

    test('copies pointValue', () {
      expect(base.copyWith(pointValue: 2000.0).pointValue, 2000.0);
    });

    test('copies quantity', () {
      expect(base.copyWith(quantity: 10).quantity, 10);
    });

    test('copies description', () {
      expect(base.copyWith(description: 'New reward').description, 'New reward');
    });

    test('copies type', () {
      expect(base.copyWith(type: RewardType.xpBoost).type, RewardType.xpBoost);
    });

    test('copies isLocked', () {
      expect(base.copyWith(isLocked: true).isLocked, isTrue);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(quantity: 5);
      expect(updated.pointValue, base.pointValue);
      expect(updated.description, base.description);
      expect(updated.type, base.type);
    });
  });
}
