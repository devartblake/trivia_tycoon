import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/user_model.dart';

Map<String, dynamic> _baseJson({
  String id = 'u1',
  String email = 'test@example.com',
  List<String> roles = const ['player'],
  bool isPremium = false,
  String createdAt = '2025-01-01T00:00:00.000Z',
}) =>
    {
      'id': id,
      'email': email,
      'roles': roles,
      'isPremium': isPremium,
      'createdAt': createdAt,
    };

void main() {
  // ---------------------------------------------------------------------------
  // UserModel.fromJson
  // ---------------------------------------------------------------------------

  group('UserModel.fromJson — scalar fields', () {
    test('parses id', () {
      expect(UserModel.fromJson(_baseJson(id: 'abc123')).id, 'abc123');
    });

    test('parses email', () {
      expect(UserModel.fromJson(_baseJson(email: 'alice@test.com')).email,
          'alice@test.com');
    });

    test('parses isPremium true', () {
      expect(UserModel.fromJson(_baseJson(isPremium: true)).isPremium, isTrue);
    });

    test('isPremium defaults to false when absent', () {
      final json = _baseJson();
      json.remove('isPremium');
      expect(UserModel.fromJson(json).isPremium, isFalse);
    });

    test('id defaults to empty string when absent', () {
      final json = _baseJson();
      json.remove('id');
      expect(UserModel.fromJson(json).id, '');
    });

    test('email defaults to empty string when absent', () {
      final json = _baseJson();
      json.remove('email');
      expect(UserModel.fromJson(json).email, '');
    });
  });

  group('UserModel.fromJson — roles', () {
    test('parses roles list', () {
      expect(UserModel.fromJson(_baseJson(roles: ['admin', 'player'])).roles,
          ['admin', 'player']);
    });

    test('roles defaults to empty list when absent', () {
      final json = _baseJson();
      json.remove('roles');
      expect(UserModel.fromJson(json).roles, isEmpty);
    });
  });

  group('UserModel.fromJson — createdAt', () {
    test('parses createdAt month', () {
      final user =
          UserModel.fromJson(_baseJson(createdAt: '2025-06-15T00:00:00.000Z'));
      expect(user.createdAt.month, 6);
    });

    test('createdAt falls back to now when null', () {
      final before = DateTime.now();
      final json = _baseJson();
      json['createdAt'] = null;
      final user = UserModel.fromJson(json);
      expect(
          user.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });

    test('createdAt falls back to now when invalid string', () {
      final json = _baseJson();
      json['createdAt'] = 'not-a-date';
      final before = DateTime.now();
      final user = UserModel.fromJson(json);
      expect(
          user.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // UserModel.toJson
  // ---------------------------------------------------------------------------

  group('UserModel.toJson', () {
    test('serializes id', () {
      expect(UserModel.fromJson(_baseJson(id: 'x1')).toJson()['id'], 'x1');
    });

    test('serializes email', () {
      expect(UserModel.fromJson(_baseJson(email: 'b@b.com')).toJson()['email'],
          'b@b.com');
    });

    test('serializes isPremium', () {
      expect(
          UserModel.fromJson(_baseJson(isPremium: true)).toJson()['isPremium'],
          isTrue);
    });

    test('serializes roles', () {
      expect(UserModel.fromJson(_baseJson(roles: ['mod'])).toJson()['roles'],
          ['mod']);
    });

    test('serializes createdAt as ISO string', () {
      expect(
          UserModel.fromJson(_baseJson()).toJson()['createdAt'], isA<String>());
    });

    test('round-trip preserves all fields', () {
      final original = UserModel.fromJson(
          _baseJson(id: 'rt1', email: 'rt@test.com', isPremium: true));
      final restored = UserModel.fromJson(original.toJson());
      expect(restored.id, 'rt1');
      expect(restored.email, 'rt@test.com');
      expect(restored.isPremium, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // UserModel.copyWith
  // ---------------------------------------------------------------------------

  group('UserModel.copyWith', () {
    final base = UserModel.fromJson(_baseJson());

    test('copies id', () {
      expect(base.copyWith(id: 'new_id').id, 'new_id');
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
      final updated = base.copyWith(id: 'changed');
      expect(updated.email, base.email);
      expect(updated.isPremium, base.isPremium);
      expect(updated.roles, base.roles);
    });
  });
}
