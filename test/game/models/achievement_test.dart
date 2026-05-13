import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/achievement.dart';

Map<String, dynamic> _baseJson({
  String id = 'ach1',
  String title = 'First Win',
  String description = 'Win your first match',
  bool isUnlocked = false,
  String? unlockedAt,
}) =>
    {
      'id': id,
      'title': title,
      'description': description,
      'isUnlocked': isUnlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt,
    };

void main() {
  // -------------------------------------------------------------------------
  // Constructor invariant: unlockedAt tied to isUnlocked
  // -------------------------------------------------------------------------

  group('Achievement constructor — unlockedAt invariant', () {
    test('isUnlocked=false clears unlockedAt even when provided', () {
      final a = Achievement(
        id: 'a1',
        title: 'T',
        description: 'D',
        isUnlocked: false,
        unlockedAt: DateTime(2025, 1, 1),
      );
      expect(a.unlockedAt, isNull);
    });

    test('isUnlocked=true sets unlockedAt to provided value', () {
      final dt = DateTime(2025, 6, 15);
      final a = Achievement(
        id: 'a1',
        title: 'T',
        description: 'D',
        isUnlocked: true,
        unlockedAt: dt,
      );
      expect(a.unlockedAt, dt);
    });

    test('isUnlocked=true with null unlockedAt uses DateTime.now()', () {
      final before = DateTime.now();
      final a = Achievement(
        id: 'a1',
        title: 'T',
        description: 'D',
        isUnlocked: true,
      );
      expect(a.unlockedAt, isNotNull);
      expect(a.unlockedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Achievement.fromJson
  // -------------------------------------------------------------------------

  group('Achievement.fromJson — scalar fields', () {
    test('parses id', () {
      expect(Achievement.fromJson(_baseJson(id: 'ach99')).id, 'ach99');
    });

    test('parses title', () {
      expect(Achievement.fromJson(_baseJson(title: 'Grand Master')).title,
          'Grand Master');
    });

    test('parses description', () {
      expect(
          Achievement.fromJson(_baseJson(description: 'Reach level 50'))
              .description,
          'Reach level 50');
    });

    test('parses isUnlocked true', () {
      expect(
          Achievement.fromJson(_baseJson(isUnlocked: true)).isUnlocked, isTrue);
    });

    test('isUnlocked defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isUnlocked');
      expect(Achievement.fromJson(json).isUnlocked, isFalse);
    });

    test('parses unlockedAt', () {
      final a = Achievement.fromJson(
          _baseJson(isUnlocked: true, unlockedAt: '2025-07-04T00:00:00.000Z'));
      expect(a.unlockedAt, isNotNull);
      expect(a.unlockedAt!.month, 7);
    });

    test('unlockedAt is null when absent', () {
      expect(Achievement.fromJson(_baseJson()).unlockedAt, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Achievement.unlock()
  // -------------------------------------------------------------------------

  group('Achievement.unlock()', () {
    test('sets isUnlocked to true', () {
      final a = Achievement.fromJson(_baseJson());
      expect(a.unlock().isUnlocked, isTrue);
    });

    test('sets unlockedAt when not previously set', () {
      final a = Achievement.fromJson(_baseJson());
      expect(a.unlock().unlockedAt, isNotNull);
    });

    test('preserves existing unlockedAt when already set', () {
      final a = Achievement.fromJson(
          _baseJson(isUnlocked: true, unlockedAt: '2025-01-15T00:00:00.000Z'));
      final unlocked = a.unlock();
      expect(unlocked.unlockedAt!.month, 1);
      expect(unlocked.unlockedAt!.day, 15);
    });

    test('preserves id, title, description', () {
      final a = Achievement.fromJson(
          _baseJson(id: 'ach5', title: 'Speed Demon'));
      final unlocked = a.unlock();
      expect(unlocked.id, 'ach5');
      expect(unlocked.title, 'Speed Demon');
    });

    test('calling unlock twice preserves first unlockedAt', () {
      final a = Achievement.fromJson(_baseJson());
      final first = a.unlock();
      final second = first.unlock();
      expect(second.unlockedAt, first.unlockedAt);
    });
  });

  // -------------------------------------------------------------------------
  // Achievement.toJson
  // -------------------------------------------------------------------------

  group('Achievement.toJson', () {
    test('serializes all fields', () {
      final a = Achievement.fromJson(
          _baseJson(id: 'ach1', title: 'Win', description: 'Desc'));
      final json = a.toJson();
      expect(json['id'], 'ach1');
      expect(json['title'], 'Win');
      expect(json['description'], 'Desc');
      expect(json['isUnlocked'], false);
    });

    test('serializes unlockedAt as ISO string when set', () {
      final a = Achievement.fromJson(
          _baseJson(isUnlocked: true, unlockedAt: '2025-05-01T00:00:00.000Z'));
      expect(a.toJson()['unlockedAt'], isA<String>());
    });

    test('unlockedAt is null in toJson when absent', () {
      expect(Achievement.fromJson(_baseJson()).toJson()['unlockedAt'], isNull);
    });

    test('round-trip preserves all fields', () {
      final original = Achievement.fromJson(_baseJson(
          id: 'ach7', title: 'Champion', description: 'Top scorer',
          isUnlocked: true, unlockedAt: '2025-08-20T00:00:00.000Z'));
      final restored = Achievement.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.isUnlocked, original.isUnlocked);
    });
  });

  // -------------------------------------------------------------------------
  // Achievement.copyWith
  // -------------------------------------------------------------------------

  group('Achievement.copyWith', () {
    late Achievement base;
    setUp(() => base = Achievement.fromJson(_baseJson()));

    test('copies title', () {
      expect(base.copyWith(title: 'New Title').title, 'New Title');
    });

    test('copies description', () {
      expect(base.copyWith(description: 'New desc').description, 'New desc');
    });

    test('copies isUnlocked', () {
      expect(base.copyWith(isUnlocked: true).isUnlocked, isTrue);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(isUnlocked: true);
      expect(updated.id, base.id);
      expect(updated.description, base.description);
    });
  });

  // -------------------------------------------------------------------------
  // Achievement equality
  // -------------------------------------------------------------------------

  group('Achievement — equality', () {
    test('equal when all fields match', () {
      final a = Achievement.fromJson(_baseJson());
      final b = Achievement.fromJson(_baseJson());
      expect(a, equals(b));
    });

    test('not equal when id differs', () {
      final a = Achievement.fromJson(_baseJson(id: 'a1'));
      final b = Achievement.fromJson(_baseJson(id: 'a2'));
      expect(a, isNot(equals(b)));
    });

    test('not equal when isUnlocked differs', () {
      final a = Achievement.fromJson(_baseJson(isUnlocked: false));
      final b = Achievement.fromJson(
          _baseJson(isUnlocked: true, unlockedAt: '2025-01-01T00:00:00.000Z'));
      expect(a, isNot(equals(b)));
    });

    test('hashCode equal for equal objects', () {
      final a = Achievement.fromJson(_baseJson());
      final b = Achievement.fromJson(_baseJson());
      expect(a.hashCode, b.hashCode);
    });
  });
}
