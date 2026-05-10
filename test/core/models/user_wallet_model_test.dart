import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/user_wallet_model.dart';

void main() {
  group('UserWallet', () {
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
  });
}
