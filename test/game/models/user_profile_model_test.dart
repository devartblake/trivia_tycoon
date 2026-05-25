import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/user_profile_model.dart';

Map<String, dynamic> _baseJson({
  String userId = 'uid1',
  String email = 'profile@example.com',
  bool isPremium = false,
  List<String> roles = const ['player'],
}) =>
    {
      'userId': userId,
      'email': email,
      'isPremium': isPremium,
      'roles': roles,
    };

void main() {
  // ---------------------------------------------------------------------------
  // UserModel.fromJson (user_profile_model.dart)
  // ---------------------------------------------------------------------------

  group('UserModel (profile).fromJson — scalar fields', () {
    test('parses userId', () {
      expect(
          UserModel.fromJson(_baseJson(userId: 'uid_abc')).userId, 'uid_abc');
    });

    test('parses email', () {
      expect(UserModel.fromJson(_baseJson(email: 'bob@test.com')).email,
          'bob@test.com');
    });

    test('parses isPremium true', () {
      expect(UserModel.fromJson(_baseJson(isPremium: true)).isPremium, isTrue);
    });

    test('isPremium defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isPremium');
      expect(UserModel.fromJson(json).isPremium, isFalse);
    });
  });

  group('UserModel (profile).fromJson — roles', () {
    test('parses roles list', () {
      expect(UserModel.fromJson(_baseJson(roles: ['admin', 'mod'])).roles,
          ['admin', 'mod']);
    });

    test('roles defaults to empty list when absent', () {
      final json = _baseJson();
      json.remove('roles');
      expect(UserModel.fromJson(json).roles, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Constructor defaults
  // ---------------------------------------------------------------------------

  group('UserModel (profile) — constructor defaults', () {
    test('isPremium defaults to false', () {
      final user = UserModel(userId: 'u1', email: 'a@b.com');
      expect(user.isPremium, isFalse);
    });

    test('roles defaults to [player]', () {
      final user = UserModel(userId: 'u1', email: 'a@b.com');
      expect(user.roles, ['player']);
    });
  });

  // ---------------------------------------------------------------------------
  // UserModel.toJson
  // ---------------------------------------------------------------------------

  group('UserModel (profile).toJson', () {
    test('serializes userId', () {
      expect(UserModel.fromJson(_baseJson(userId: 'uid_x')).toJson()['userId'],
          'uid_x');
    });

    test('serializes email', () {
      expect(UserModel.fromJson(_baseJson(email: 'x@y.com')).toJson()['email'],
          'x@y.com');
    });

    test('serializes isPremium', () {
      expect(
          UserModel.fromJson(_baseJson(isPremium: true)).toJson()['isPremium'],
          isTrue);
    });

    test('serializes roles', () {
      expect(UserModel.fromJson(_baseJson(roles: ['vip'])).toJson()['roles'],
          ['vip']);
    });

    test('round-trip preserves all fields', () {
      final original = UserModel.fromJson(
          _baseJson(userId: 'rt1', email: 'rt@test.com', isPremium: true));
      final restored = UserModel.fromJson(original.toJson());
      expect(restored.userId, 'rt1');
      expect(restored.email, 'rt@test.com');
      expect(restored.isPremium, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // UserModel.copyWith
  // ---------------------------------------------------------------------------

  group('UserModel (profile).copyWith', () {
    final base = UserModel.fromJson(_baseJson());

    test('copies userId', () {
      expect(base.copyWith(userId: 'new_uid').userId, 'new_uid');
    });

    test('copies email', () {
      expect(base.copyWith(email: 'new@test.com').email, 'new@test.com');
    });

    test('copies isPremium', () {
      expect(base.copyWith(isPremium: true).isPremium, isTrue);
    });

    test('copies roles', () {
      expect(base.copyWith(roles: ['admin']).roles, ['admin']);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(userId: 'changed');
      expect(updated.email, base.email);
      expect(updated.isPremium, base.isPremium);
    });
  });
}
