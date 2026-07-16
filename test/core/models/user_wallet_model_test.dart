import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/models/user_wallet_model.dart';

void main() {
  group('UserWallet — fromJson field mapping', () {
    test('maps backend wallet fields to app currency names', () {
      final wallet = UserWallet.fromJson({
        'playerId': 'player-123',
        'credits': 4200,
        'neuralXp': 875,
        'synapseShards': 19,
        'updatedAtUtc': '2026-05-10T12:34:56Z',
      });

      expect(wallet.playerId, 'player-123');
      expect(wallet.coins, 4200);
      expect(wallet.xp, 875);
      expect(wallet.diamonds, 19);
      expect(wallet.updatedAtUtc, DateTime.parse('2026-05-10T12:34:56Z'));
    });

    test('defaults missing numeric wallet fields to zero', () {
      final wallet = UserWallet.fromJson({'playerId': 'player-123'});

      expect(wallet.coins, 0);
      expect(wallet.xp, 0);
      expect(wallet.diamonds, 0);
    });

    test('maps credits → coins (not neuralXp or synapseShards)', () {
      final wallet = UserWallet.fromJson({
        'credits': 500,
        'neuralXp': 0,
        'synapseShards': 0,
      });
      expect(wallet.coins, 500);
      expect(wallet.xp, 0);
      expect(wallet.diamonds, 0);
    });

    test('maps neuralXp → xp independently', () {
      final wallet = UserWallet.fromJson({
        'credits': 0,
        'neuralXp': 1200,
        'synapseShards': 0,
      });
      expect(wallet.xp, 1200);
      expect(wallet.coins, 0);
      expect(wallet.diamonds, 0);
    });

    test('maps synapseShards → diamonds independently', () {
      final wallet = UserWallet.fromJson({
        'credits': 0,
        'neuralXp': 0,
        'synapseShards': 75,
      });
      expect(wallet.diamonds, 75);
      expect(wallet.coins, 0);
      expect(wallet.xp, 0);
    });

    test('accepts double values and truncates to int', () {
      final wallet = UserWallet.fromJson({
        'playerId': 'p1',
        'credits': 100.9,
        'neuralXp': 200.1,
        'synapseShards': 50.5,
      });
      expect(wallet.coins, 100);
      expect(wallet.xp, 200);
      expect(wallet.diamonds, 50);
    });

    test('uses empty string when playerId is absent', () {
      final wallet = UserWallet.fromJson({'credits': 10});
      expect(wallet.playerId, '');
    });

    test('updatedAtUtc is null when field is absent', () {
      final wallet = UserWallet.fromJson({'playerId': 'p1'});
      expect(wallet.updatedAtUtc, isNull);
    });

    test('large balance values are preserved', () {
      final wallet = UserWallet.fromJson({
        'playerId': 'whale',
        'credits': 9999999,
        'neuralXp': 5000000,
        'synapseShards': 100000,
      });
      expect(wallet.coins, 9999999);
      expect(wallet.xp, 5000000);
      expect(wallet.diamonds, 100000);
    });
  });

  // -------------------------------------------------------------------------
  // UserWallet.empty
  // -------------------------------------------------------------------------

  group('UserWallet.empty', () {
    test('has zero coins', () => expect(UserWallet.empty.coins, 0));
    test('has zero xp', () => expect(UserWallet.empty.xp, 0));
    test('has zero diamonds', () => expect(UserWallet.empty.diamonds, 0));
    test('has empty playerId', () => expect(UserWallet.empty.playerId, ''));
    test('updatedAtUtc is null',
        () => expect(UserWallet.empty.updatedAtUtc, isNull));
  });

  // -------------------------------------------------------------------------
  // UserWallet — direct constructor
  // -------------------------------------------------------------------------

  group('UserWallet — constructor', () {
    test('stores all provided fields', () {
      final now = DateTime.utc(2030, 6, 1);
      final wallet = UserWallet(
        playerId: 'abc',
        coins: 100,
        xp: 500,
        diamonds: 10,
        updatedAtUtc: now,
      );
      expect(wallet.playerId, 'abc');
      expect(wallet.coins, 100);
      expect(wallet.xp, 500);
      expect(wallet.diamonds, 10);
      expect(wallet.updatedAtUtc, now);
    });

    test('updatedAtUtc defaults to null', () {
      final wallet = UserWallet(
        playerId: 'x',
        coins: 0,
        xp: 0,
        diamonds: 0,
      );
      expect(wallet.updatedAtUtc, isNull);
    });
  });
}
