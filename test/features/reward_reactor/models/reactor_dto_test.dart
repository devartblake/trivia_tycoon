import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_animation_hints.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_claim_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_reward_line.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_reward_preview.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_spin_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/user_rewards_response.dart';

void main() {
  group('ReactorSpinResponse', () {
    final fullJson = {
      'spinId': 'spin-123',
      'status': 'pending_claim',
      'expiresAtUtc': '2026-05-21T12:00:00.000Z',
      'cooldownUntilUtc': '2026-05-21T13:00:00.000Z',
      'animation': {
        'layout': 'reel3',
        'symbols': ['coin', 'gem', 'star'],
        'winningSymbolIndexes': [0, 1, 2],
        'rarity': 'rare',
        'intensity': 'high',
      },
      'rewardPreview': {
        'rewardId': 'daily-login',
        'displayName': 'Daily Login Reward',
        'lines': [
          {'type': 'coins', 'label': '50 Coins', 'amount': 50},
        ],
      },
      'claimToken': 'token-abc',
    };

    test('fromJson round-trips with all fields', () {
      final response = ReactorSpinResponse.fromJson(fullJson);
      expect(response.spinId, 'spin-123');
      expect(response.status, 'pending_claim');
      expect(response.cooldownUntilUtc, isNotNull);
      expect(response.animation.layout, 'reel3');
      expect(response.animation.symbols, ['coin', 'gem', 'star']);
      expect(response.animation.winningSymbolIndexes, [0, 1, 2]);
      expect(response.animation.rarity, 'rare');
      expect(response.rewardPreview.displayName, 'Daily Login Reward');
      expect(response.rewardPreview.lines.first.amount, 50);
      expect(response.claimToken, 'token-abc');
    });

    test('fromJson handles missing optional fields', () {
      final minimal = Map<String, dynamic>.from(fullJson)
        ..remove('cooldownUntilUtc');
      final minimal2 = {
        ...minimal,
        'rewardPreview': {
          'rewardId': 'r1',
          'displayName': 'Test',
          'lines': [
            {'type': 'coins', 'label': 'Coins'}, // no amount, no iconUrl
          ],
        },
      };
      final response = ReactorSpinResponse.fromJson(minimal2);
      expect(response.cooldownUntilUtc, isNull);
      expect(response.rewardPreview.lines.first.amount, isNull);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = ReactorSpinResponse.fromJson(fullJson);
      final restored = ReactorSpinResponse.fromJson(original.toJson());
      expect(restored.spinId, original.spinId);
      expect(restored.claimToken, original.claimToken);
      expect(restored.animation.winningSymbolIndexes,
          original.animation.winningSymbolIndexes);
    });
  });

  group('ReactorAnimationHints', () {
    test('winningSymbolIndexes parsed as List<int>', () {
      final hints = ReactorAnimationHints.fromJson({
        'layout': 'reel3',
        'symbols': ['coin'],
        'winningSymbolIndexes': [0, 3, 6],
        'rarity': 'common',
        'intensity': 'low',
      });
      expect(hints.winningSymbolIndexes, isA<List<int>>());
      expect(hints.winningSymbolIndexes, [0, 3, 6]);
    });

    test('empty symbols list is handled gracefully', () {
      final hints = ReactorAnimationHints.fromJson({
        'layout': 'reel3',
        'symbols': [],
        'winningSymbolIndexes': [],
        'rarity': 'common',
        'intensity': 'medium',
      });
      expect(hints.symbols, isEmpty);
      expect(hints.winningSymbolIndexes, isEmpty);
    });
  });

  group('ReactorClaimResponse', () {
    for (final status in ['applied', 'duplicate', 'expired', 'cooldown']) {
      test('fromJson maps status "$status"', () {
        final response = ReactorClaimResponse.fromJson({
          'spinId': 'spin-1',
          'status': status,
        });
        expect(response.status, status);
        expect(response.spinId, 'spin-1');
        expect(response.reward, isNull);
        expect(response.walletSnapshot, isNull);
      });
    }

    test('isApplied / isDuplicate / isExpired / isCooldown flags', () {
      expect(ReactorClaimResponse.fromJson({'spinId': 's', 'status': 'applied'}).isApplied, isTrue);
      expect(ReactorClaimResponse.fromJson({'spinId': 's', 'status': 'duplicate'}).isDuplicate, isTrue);
      expect(ReactorClaimResponse.fromJson({'spinId': 's', 'status': 'expired'}).isExpired, isTrue);
      expect(ReactorClaimResponse.fromJson({'spinId': 's', 'status': 'cooldown'}).isCooldown, isTrue);
    });
  });

  group('UserRewardsResponse', () {
    test('fromJson with empty pendingRewards list', () {
      final response = UserRewardsResponse.fromJson({
        'pendingRewards': [],
        'recentRewards': [],
      });
      expect(response.pendingRewards, isEmpty);
      expect(response.recentRewards, isEmpty);
    });

    test('UserRewardsResponse.empty() constructor', () {
      const response = UserRewardsResponse.empty();
      expect(response.pendingRewards, isEmpty);
      expect(response.recentRewards, isEmpty);
    });
  });

  group('ReactorRewardLine', () {
    test('fromJson with all optional fields', () {
      final line = ReactorRewardLine.fromJson({
        'type': 'gems',
        'label': '10 Gems',
        'amount': 10,
        'iconUrl': 'https://cdn.example.com/gem.png',
      });
      expect(line.type, 'gems');
      expect(line.amount, 10);
      expect(line.iconUrl, isNotNull);
    });

    test('fromJson without optional fields', () {
      final line = ReactorRewardLine.fromJson({'type': 'xp', 'label': 'XP'});
      expect(line.amount, isNull);
      expect(line.iconUrl, isNull);
    });
  });

  group('ReactorRewardPreview', () {
    test('fromJson with multiple lines', () {
      final preview = ReactorRewardPreview.fromJson({
        'rewardId': 'multi',
        'displayName': 'Big Reward',
        'lines': [
          {'type': 'coins', 'label': '100 Coins', 'amount': 100},
          {'type': 'xp', 'label': '50 XP', 'amount': 50},
        ],
      });
      expect(preview.lines.length, 2);
      expect(preview.lines[0].type, 'coins');
      expect(preview.lines[1].type, 'xp');
    });
  });
}
