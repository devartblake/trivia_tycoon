import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/multiplayer/domain/entities/player_presence.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PlayerPresence _p({
  String id = 'p1',
  String name = 'Alice',
  String? avatarUrl,
  bool isHost = false,
}) =>
    PlayerPresence(id: id, name: name, avatarUrl: avatarUrl, isHost: isHost);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Construction
  // -------------------------------------------------------------------------

  group('PlayerPresence construction', () {
    test('stores all provided fields', () {
      final p =
          _p(id: 'u1', name: 'Bob', avatarUrl: 'https://img', isHost: true);
      expect(p.id, 'u1');
      expect(p.name, 'Bob');
      expect(p.avatarUrl, 'https://img');
      expect(p.isHost, isTrue);
    });

    test('isHost defaults to false', () {
      expect(_p().isHost, isFalse);
    });

    test('avatarUrl defaults to null', () {
      expect(_p().avatarUrl, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('PlayerPresence.copyWith', () {
    test('returns identical presence when no arguments given', () {
      final p = _p(avatarUrl: 'https://img', isHost: true);
      final copy = p.copyWith();
      expect(copy.id, p.id);
      expect(copy.name, p.name);
      expect(copy.avatarUrl, p.avatarUrl);
      expect(copy.isHost, p.isHost);
    });

    test('replaces id', () {
      expect(_p(id: 'p1').copyWith(id: 'p2').id, 'p2');
    });

    test('replaces name', () {
      expect(_p(name: 'Alice').copyWith(name: 'Bob').name, 'Bob');
    });

    test('replaces avatarUrl', () {
      expect(
        _p().copyWith(avatarUrl: 'https://new').avatarUrl,
        'https://new',
      );
    });

    test('replaces isHost', () {
      expect(_p(isHost: false).copyWith(isHost: true).isHost, isTrue);
    });

    test('clearAvatar sets avatarUrl to null', () {
      final p = _p(avatarUrl: 'https://img');
      expect(p.copyWith(clearAvatar: true).avatarUrl, isNull);
    });

    test('avatarUrl argument is ignored when clearAvatar is true', () {
      final p = _p(avatarUrl: 'https://old');
      final copy = p.copyWith(avatarUrl: 'https://new', clearAvatar: true);
      expect(copy.avatarUrl, isNull);
    });

    test('null avatarUrl stays null without clearAvatar', () {
      expect(_p().copyWith().avatarUrl, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Equality and hashCode
  // -------------------------------------------------------------------------

  group('PlayerPresence equality', () {
    test('equal presences compare as equal', () {
      expect(_p(id: 'p1', name: 'Alice'), _p(id: 'p1', name: 'Alice'));
    });

    test('different id → not equal', () {
      expect(_p(id: 'p1'), isNot(_p(id: 'p2')));
    });

    test('different name → not equal', () {
      expect(_p(name: 'Alice'), isNot(_p(name: 'Bob')));
    });

    test('different avatarUrl → not equal', () {
      expect(
        _p(avatarUrl: 'https://a'),
        isNot(_p(avatarUrl: 'https://b')),
      );
    });

    test('null vs set avatarUrl → not equal', () {
      expect(_p(), isNot(_p(avatarUrl: 'https://img')));
    });

    test('different isHost → not equal', () {
      expect(_p(isHost: true), isNot(_p(isHost: false)));
    });

    test('equal presences have same hashCode', () {
      expect(_p().hashCode, _p().hashCode);
    });

    test('different presences generally have different hashCodes', () {
      expect(_p(id: 'p1').hashCode, isNot(_p(id: 'p2').hashCode));
    });
  });

  // -------------------------------------------------------------------------
  // toString
  // -------------------------------------------------------------------------

  group('PlayerPresence.toString', () {
    test('contains id', () {
      expect(_p(id: 'user-42').toString(), contains('user-42'));
    });

    test('contains name', () {
      expect(_p(name: 'Charlie').toString(), contains('Charlie'));
    });

    test('reflects isHost value', () {
      expect(_p(isHost: true).toString(), contains('true'));
    });

    test('reports avatarUrl presence as bool', () {
      expect(_p(avatarUrl: 'https://img').toString(), contains('true'));
      expect(_p().toString(), contains('false'));
    });
  });
}
