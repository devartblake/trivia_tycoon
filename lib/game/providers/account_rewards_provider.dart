import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';

import 'auth_providers.dart';
import 'core_providers.dart';
import 'wallet_providers.dart';
import 'xp_provider.dart';

class AccountRewardDefinition {
  final String key;
  final String title;
  final String description;
  final int coins;
  final int xp;
  final String? item;

  const AccountRewardDefinition({
    required this.key,
    required this.title,
    required this.description,
    this.coins = 0,
    this.xp = 0,
    this.item,
  });

  String get rewardText {
    final parts = <String>[
      if (coins > 0) '$coins coins',
      if (xp > 0) '$xp XP',
      if (item != null) item!,
    ];
    return parts.join(' + ');
  }
}

const accountRewardDefinitions = <AccountRewardDefinition>[
  AccountRewardDefinition(
    key: 'onboarding_complete',
    title: 'Complete onboarding',
    description: 'Finish your first setup and starter challenge.',
    coins: 250,
    xp: 50,
    item: '1 hint power-up',
  ),
  AccountRewardDefinition(
    key: 'website_account_linked',
    title: 'Link a web account',
    description: 'Create or connect an online account for cross-device play.',
    coins: 500,
    xp: 100,
    item: 'Account Linked badge',
  ),
  AccountRewardDefinition(
    key: 'phone_or_qr_linked',
    title: 'Link with QR or code',
    description: 'Connect this device to a browser session.',
    coins: 250,
    item: '1 revive',
  ),
  AccountRewardDefinition(
    key: 'discord_connected',
    title: 'Connect Discord',
    description: 'Join community features and friend discovery.',
    coins: 300,
    item: '1 freeze power-up',
  ),
  AccountRewardDefinition(
    key: 'twitch_connected',
    title: 'Connect Twitch',
    description: 'Prepare for creator and live-event rewards.',
    coins: 300,
    item: '1 double-xp boost',
  ),
  AccountRewardDefinition(
    key: 'x_connected',
    title: 'Connect X',
    description: 'Unlock social sharing rewards.',
    coins: 300,
    item: 'Profile flair',
  ),
];

final accountRewardsProvider =
    StateNotifierProvider<AccountRewardsNotifier, AsyncValue<Set<String>>>(
        (ref) {
  return AccountRewardsNotifier(ref)..load();
});

class AccountRewardsNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  static const _boxName = 'settings';
  static const _claimedKey = 'account_link_reward_claims';

  final Ref ref;

  AccountRewardsNotifier(this.ref) : super(const AsyncValue.loading());

  Future<Box> _box() async => Hive.openBox(_boxName);

  Future<void> load() async {
    try {
      final box = await _box();
      final raw = box.get(_claimedKey, defaultValue: <String>[]);
      final localClaims = Set<String>.from(raw as Iterable);
      final backendClaims = await _loadBackendClaims();
      final authoritativeClaims = backendClaims ?? localClaims;
      if (!_setEquals(authoritativeClaims, localClaims)) {
        await box.put(_claimedKey, authoritativeClaims.toList()..sort());
      }
      state = AsyncValue.data(authoritativeClaims);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> claim(
    String rewardKey, {
    bool allowLocalFallback = false,
  }) async {
    AccountRewardDefinition? definition;
    for (final reward in accountRewardDefinitions) {
      if (reward.key == rewardKey) {
        definition = reward;
        break;
      }
    }
    if (definition == null) return false;

    final current = state.valueOrNull ?? const <String>{};
    if (current.contains(rewardKey)) return false;

    Map<String, dynamic>? serverState;
    final useLocalFallback = allowLocalFallback || _usesLocalRewardState();
    if (!useLocalFallback) {
      try {
        serverState = await _claimOnBackend(rewardKey);
        await _syncFromServerState(serverState);
      } catch (e) {
        LogManager.debug('[AccountRewards] Backend claim unavailable: $e');
        return false;
      }
    }

    if (serverState == null && definition.coins > 0) {
      final wallet = ref.read(walletServiceProvider);
      wallet.addCoins(definition.coins);
      ref.read(playerCoinsProvider.notifier).state = wallet.coins;
    }
    if (serverState == null && definition.xp > 0) {
      await ref
          .read(serviceManagerProvider)
          .playerProfileService
          .addXP(definition.xp);
    }

    final serverClaims = _claimedKeysFrom(serverState);
    final updated = {
      ...current,
      ...serverClaims,
      rewardKey,
    };
    final box = await _box();
    await box.put(_claimedKey, updated.toList()..sort());
    state = AsyncValue.data(updated);
    if (serverState == null) {
      LogManager.debug(
        '[AccountRewards] Applied local fallback for $rewardKey',
      );
    }
    return true;
  }

  Future<Map<String, dynamic>> _claimOnBackend(String rewardKey) async {
    final playerId =
        await ref.read(serviceManagerProvider).playerProfileService.getUserId();
    return ref.read(serviceManagerProvider).apiService.post(
      '/account/rewards/claim',
      body: {
        'rewardKey': rewardKey,
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      },
    );
  }

  Future<Set<String>?> _loadBackendClaims() async {
    if (_usesLocalRewardState()) return null;

    try {
      final response = await ref.read(serviceManagerProvider).apiService.get(
            '/account/rewards/status',
          );
      final raw = response['claimedRewardKeys'] ?? response['claimed'];
      if (raw is Iterable) {
        return raw.map((value) => value.toString()).toSet();
      }
    } on ApiRequestException catch (e) {
      if (e.statusCode != 404) {
        LogManager.debug('[AccountRewards] Backend status unavailable: $e');
      }
    } catch (e) {
      LogManager.debug('[AccountRewards] Backend status unavailable: $e');
    }
    return null;
  }

  bool _usesLocalRewardState() {
    final identity = ref.read(playerIdentityProvider);
    return identity.kind == PlayerIdentityKind.anonymousDevice;
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  Set<String> _claimedKeysFrom(Map<String, dynamic>? response) {
    if (response == null) return const <String>{};
    final raw = response['claimedRewardKeys'] ??
        response['claimedRewards'] ??
        response['claimed'];
    if (raw is Iterable) {
      return raw.map((value) => value.toString()).toSet();
    }
    return const <String>{};
  }

  Future<void> _syncFromServerState(Map<String, dynamic> response) async {
    final walletJson = _walletMapFrom(response);
    if (walletJson == null) return;

    final coins = _intFromAny(
      walletJson['credits'] ?? walletJson['coins'] ?? walletJson['coinBalance'],
    );
    final gems = _intFromAny(
      walletJson['synapseShards'] ??
          walletJson['gems'] ??
          walletJson['diamonds'] ??
          walletJson['diamondBalance'],
    );
    final xp = _intFromAny(
      walletJson['neuralXp'] ?? walletJson['xp'] ?? walletJson['currentXP'],
    );

    if (coins != null || gems != null) {
      final wallet = ref.read(walletServiceProvider);
      await wallet.setBalances(
        coins: coins ?? wallet.coins,
        gems: gems ?? wallet.gems,
      );
      ref.read(playerCoinsProvider.notifier).state = wallet.coins;
      ref.read(playerGemsProvider.notifier).state = wallet.gems;
    }
    if (xp != null) {
      ref.read(playerXPProvider.notifier).state = xp;
    }
  }

  Map<String, dynamic>? _walletMapFrom(Map<String, dynamic> response) {
    final raw = response['wallet'] ??
        response['balances'] ??
        response['economy'] ??
        response['player'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return response;
  }

  int? _intFromAny(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
