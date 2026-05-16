import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/tier_model.dart';

Map<String, dynamic> _baseJson({
  int id = 1,
  String name = 'Bronze',
  String description = 'Entry-level tier',
  int icon = 0xe3af, // Icons.military_tech codePoint
  int primaryColor = 0xFFCD7F32,
  int secondaryColor = 0xFF8B5E3C,
  int requiredXP = 0,
  int requiredLevel = 1,
  List<String>? rewards,
  bool isUnlocked = false,
  bool isCurrent = false,
  String? unlockedAt,
}) =>
    {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'requiredXP': requiredXP,
      'requiredLevel': requiredLevel,
      'rewards': rewards ?? ['Bronze Badge', '100 Coins'],
      'isUnlocked': isUnlocked,
      'isCurrent': isCurrent,
      if (unlockedAt != null) 'unlockedAt': unlockedAt,
    };

void main() {
  // -------------------------------------------------------------------------
  // TierModel.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('TierModel.fromJson — scalar fields', () {
    test('parses id', () {
      expect(TierModel.fromJson(_baseJson(id: 5)).id, 5);
    });

    test('parses name', () {
      expect(TierModel.fromJson(_baseJson(name: 'Gold')).name, 'Gold');
    });

    test('parses description', () {
      expect(TierModel.fromJson(_baseJson(description: 'Top tier')).description,
          'Top tier');
    });

    test('parses requiredXP', () {
      expect(TierModel.fromJson(_baseJson(requiredXP: 5000)).requiredXP, 5000);
    });

    test('parses requiredLevel', () {
      expect(
          TierModel.fromJson(_baseJson(requiredLevel: 10)).requiredLevel, 10);
    });

    test('parses rewards list', () {
      final tier = TierModel.fromJson(
          _baseJson(rewards: ['Badge', 'Coin Pack', 'Skin']));
      expect(tier.rewards, ['Badge', 'Coin Pack', 'Skin']);
    });

    test('parses isUnlocked', () {
      expect(
          TierModel.fromJson(_baseJson(isUnlocked: true)).isUnlocked, isTrue);
    });

    test('isUnlocked defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isUnlocked');
      expect(TierModel.fromJson(json).isUnlocked, isFalse);
    });

    test('parses isCurrent', () {
      expect(TierModel.fromJson(_baseJson(isCurrent: true)).isCurrent, isTrue);
    });

    test('isCurrent defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isCurrent');
      expect(TierModel.fromJson(json).isCurrent, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // TierModel.fromJson — Color / Icon
  // -------------------------------------------------------------------------

  group('TierModel.fromJson — color and icon', () {
    test('parses primaryColor', () {
      final tier = TierModel.fromJson(_baseJson(primaryColor: 0xFFFFD700));
      expect(tier.primaryColor, const Color(0xFFFFD700));
    });

    test('parses secondaryColor', () {
      final tier = TierModel.fromJson(_baseJson(secondaryColor: 0xFF8B5CF6));
      expect(tier.secondaryColor, const Color(0xFF8B5CF6));
    });

    test('parses icon codePoint', () {
      final tier =
          TierModel.fromJson(_baseJson(icon: Icons.military_tech.codePoint));
      expect(tier.icon.codePoint, Icons.military_tech.codePoint);
    });
  });

  // -------------------------------------------------------------------------
  // TierModel.fromJson — DateTime
  // -------------------------------------------------------------------------

  group('TierModel.fromJson — unlockedAt', () {
    test('parses unlockedAt', () {
      final tier =
          TierModel.fromJson(_baseJson(unlockedAt: '2025-06-01T00:00:00.000Z'));
      expect(tier.unlockedAt, isNotNull);
      expect(tier.unlockedAt!.month, 6);
    });

    test('unlockedAt is null when absent', () {
      expect(TierModel.fromJson(_baseJson()).unlockedAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // TierModel — gradient
  // -------------------------------------------------------------------------

  group('TierModel — gradient', () {
    test('gradient uses primary and secondary colors', () {
      final tier = TierModel.fromJson(
        _baseJson(primaryColor: 0xFFFFD700, secondaryColor: 0xFF8B5CF6),
      );
      expect(tier.gradient.colors.first, const Color(0xFFFFD700));
      expect(tier.gradient.colors.last, const Color(0xFF8B5CF6));
    });

    test('gradient alignment is topLeft → bottomRight', () {
      final tier = TierModel.fromJson(_baseJson());
      expect(tier.gradient.begin, Alignment.topLeft);
      expect(tier.gradient.end, Alignment.bottomRight);
    });
  });

  // -------------------------------------------------------------------------
  // TierModel.toJson
  // -------------------------------------------------------------------------

  group('TierModel.toJson', () {
    test('serializes icon as codePoint int', () {
      final tier =
          TierModel.fromJson(_baseJson(icon: Icons.military_tech.codePoint));
      expect(tier.toJson()['icon'], isA<int>());
    });

    test('serializes primaryColor as int', () {
      final tier = TierModel.fromJson(_baseJson(primaryColor: 0xFFFFD700));
      expect(tier.toJson()['primaryColor'], 0xFFFFD700);
    });

    test('serializes unlockedAt as ISO string when set', () {
      final tier =
          TierModel.fromJson(_baseJson(unlockedAt: '2025-06-01T00:00:00.000Z'));
      expect(tier.toJson()['unlockedAt'], isA<String>());
    });

    test('unlockedAt is null in toJson when absent', () {
      expect(TierModel.fromJson(_baseJson()).toJson()['unlockedAt'], isNull);
    });

    test('serializes rewards as list', () {
      final tier = TierModel.fromJson(_baseJson(rewards: ['A', 'B']));
      expect(tier.toJson()['rewards'], ['A', 'B']);
    });

    test('round-trip preserves name, requiredXP, requiredLevel', () {
      final original = TierModel.fromJson(
          _baseJson(name: 'Platinum', requiredXP: 99999, requiredLevel: 50));
      final restored = TierModel.fromJson(original.toJson());
      expect(restored.name, 'Platinum');
      expect(restored.requiredXP, 99999);
      expect(restored.requiredLevel, 50);
    });
  });

  // -------------------------------------------------------------------------
  // TierModel.copyWith
  // -------------------------------------------------------------------------

  group('TierModel.copyWith', () {
    late TierModel base;
    setUp(() => base = TierModel.fromJson(_baseJson()));

    test('copies isUnlocked', () {
      expect(base.copyWith(isUnlocked: true).isUnlocked, isTrue);
    });

    test('copies isCurrent', () {
      expect(base.copyWith(isCurrent: true).isCurrent, isTrue);
    });

    test('copies name', () {
      expect(base.copyWith(name: 'Diamond').name, 'Diamond');
    });

    test('copies requiredXP', () {
      expect(base.copyWith(requiredXP: 10000).requiredXP, 10000);
    });

    test('copies rewards', () {
      expect(base.copyWith(rewards: ['Trophy']).rewards, ['Trophy']);
    });

    test('copies primaryColor', () {
      expect(base.copyWith(primaryColor: const Color(0xFFFF0000)).primaryColor,
          const Color(0xFFFF0000));
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(isCurrent: true);
      expect(updated.id, base.id);
      expect(updated.name, base.name);
      expect(updated.requiredXP, base.requiredXP);
    });
  });
}
