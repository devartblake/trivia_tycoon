import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/models/store/premium_store_model.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/store/store_service.dart';
import 'package:trivia_tycoon/game/controllers/coin_balance_notifier.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/game/state/premium_profile_state.dart';
import 'package:trivia_tycoon/screens/store/premium_store.dart';
import 'package:trivia_tycoon/screens/store/widgets/reward_center.dart';
import 'package:trivia_tycoon/screens/store/widgets/sale_info.dart';

class _FakeStorage extends GeneralKeyValueStorageService {
  _FakeStorage({this.initialInt = 0});

  final int initialInt;
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  Future<int> getInt(String key) async {
    final value = _values[key];
    if (value is int) return value;
    return initialInt;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }
}

class _FakeRewardStoreService implements StoreService {
  _FakeRewardStoreService({
    this.claimResponse,
    this.claimError,
  });

  final Map<String, dynamic>? claimResponse;
  final ApiRequestException? claimError;
  int claimCalls = 0;
  String? lastPlayerId;
  String? lastRewardId;

  Future<Map<String, dynamic>> claimPlayerReward({
    required String playerId,
    required String rewardId,
  }) async {
    claimCalls += 1;
    lastPlayerId = playerId;
    lastRewardId = rewardId;

    if (claimError != null) {
      throw claimError!;
    }

    return claimResponse ??
        <String, dynamic>{
          'success': true,
          'rewardId': rewardId,
          'coinsAwarded': 500,
          'newBalance': 1940,
        };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('premium store model parses current backend dto shape', () {
    final data = PremiumStoreData.fromJson({
      'adFree': {
        'title': 'Ad-Free Plans',
        'subtitle': 'Choose a lighter, uninterrupted Tycoon experience.',
        'benefits': [
          'Removes gameplay interstitial ads',
        ],
        'plans': [
          {
            'id': 'premium-monthly',
            'title': 'Monthly Ad-Free',
            'subtitle': 'Best for trying premium access',
            'priceLabel': r'$4.99 / month',
            'badge': 'Popular',
            'accentColor': '#0F766E',
            'isBestValue': false,
            'sku': 'sub:premium:monthly',
          },
          {
            'id': 'premium-seasonal',
            'title': 'Seasonal Ad-Free',
            'subtitle': 'Three months of uninterrupted play',
            'priceLabel': r'$11.99 / season',
            'badge': 'Best Value',
            'accentColor': '#1D4ED8',
            'isBestValue': true,
            'sku': 'sub:premium:seasonal',
          },
        ],
      },
      'saleInfo': null,
      'rewardCenter': {
        'title': 'Reward Center',
        'subtitle': 'Pick up daily bonuses and bonus coin drops.',
        'cards': [
          {
            'rewardId': 'daily-checkin',
            'title': 'Daily Check-In',
            'subtitle': 'Claim once per UTC day.',
            'rewardLabel': '+25 coins',
            'gradientStart': '#0EA5E9',
            'gradientEnd': '#2563EB',
            'progress': 0.0,
            'isClaimAvailable': true,
          },
        ],
      },
    });

    expect(data.adFree.plans.first.displayTitle, 'Monthly Ad-Free');
    expect(data.adFree.plans.first.price, r'$4.99 / month');
    expect(data.adFree.plans.first.tier, 'premium');
    expect(data.adFree.plans.first.billingPeriod, 'monthly');
    expect(data.adFree.defaultPurchasePlan?.billingPeriod, 'seasonal');
    expect(data.rewardCenter.cards.first.id, 'daily-checkin');
    expect(data.rewardCenter.cards.first.reward, '+25 coins');
    expect(data.rewardCenter.cards.first.isAvailable, isTrue);
    expect(data.rewardCenter.totalCount, 1);
  });

  testWidgets('premium store hides special offers when saleInfo is null',
      (tester) async {
    final storeData = PremiumStoreData(
      adFree: AdFreeConfig.fallback,
      saleInfo: null,
      rewardCenter: const RewardCenterData(
        cards: [
          RewardCard(
            id: 'catalog-card',
            title: 'Catalog Reward',
            subtitle: 'Catalog subtitle',
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            reward: '100 Coins',
            isAvailable: true,
          ),
        ],
        completedCount: 0,
        totalCount: 1,
      ),
    );

    final rewardData = const RewardCenterData(
      cards: [
        RewardCard(
          id: 'daily-checkin',
          title: 'Daily Check-in',
          subtitle: 'Day 3 of 7',
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          reward: '500 Coins',
          progress: 0.43,
          isAvailable: true,
        ),
      ],
      completedCount: 1,
      totalCount: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStoreProvider.overrideWith((ref) async => storeData),
          playerRewardsProvider.overrideWith((ref) async => rewardData),
          premiumAccessStatusProvider.overrideWith(
            (ref) async => PremiumStatus(
              isPremium: true,
              discountPercent: 0,
            ),
          ),
          coinBalanceProvider.overrideWith(
            (ref) => CoinBalanceNotifier(_FakeStorage(initialInt: 250)),
          ),
        ],
        child: const MaterialApp(home: StoreSecondaryScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Special Offers'), findsNothing);
    expect(find.text('Day 3 of 7'), findsOneWidget);
    expect(find.text('Catalog subtitle'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
  });

  testWidgets('reward claim updates coin balance and shows success dialog',
      (tester) async {
    final fakeStore = _FakeRewardStoreService(
      claimResponse: <String, dynamic>{
        'success': true,
        'rewardId': 'daily-checkin',
        'coinsAwarded': 500,
        'newBalance': 1940,
      },
    );
    final container = ProviderContainer(
      overrides: [
        storeServiceProvider.overrideWith((ref) => fakeStore),
        currentUserIdProvider.overrideWith((ref) async => 'player-123'),
        playerRewardsProvider.overrideWith(
          (ref) async => RewardCenterData.fallback,
        ),
        coinBalanceProvider.overrideWith(
          (ref) => CoinBalanceNotifier(_FakeStorage(initialInt: 100)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RewardCenter(data: RewardCenterData.fallback),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Claim').first);
    await tester.pump();
    await tester.pump();

    expect(fakeStore.claimCalls, 1);
    expect(fakeStore.lastPlayerId, 'player-123');
    expect(fakeStore.lastRewardId, 'daily-checkin');
    expect(container.read(coinBalanceProvider), 1940);
    expect(find.text('Reward Claimed!'), findsOneWidget);
  });

  testWidgets('reward claim conflict shows backend message', (tester) async {
    final fakeStore = _FakeRewardStoreService(
      claimError: ApiRequestException(
        'Daily check-in has already been claimed for today.',
        statusCode: 409,
        errorCode: 'already_claimed',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeServiceProvider.overrideWith((ref) => fakeStore),
          currentUserIdProvider.overrideWith((ref) async => 'player-123'),
          playerRewardsProvider.overrideWith(
            (ref) async => RewardCenterData.fallback,
          ),
          coinBalanceProvider.overrideWith(
            (ref) => CoinBalanceNotifier(_FakeStorage(initialInt: 100)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: RewardCenter(data: RewardCenterData.fallback),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Claim').first);
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Daily check-in has already been claimed for today.'),
      findsOneWidget,
    );
  });

  testWidgets('sale info shows ended state for expired offers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaleInfo(
            data: SaleInfoData(
              badgeText: 'FLASH SALE',
              discount: '80% OFF',
              originalPrice: r'$10',
              salePrice: r'$1.99',
              benefits: const [],
              expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Offer ended'), findsOneWidget);
  });

  test('premium plan mapping resolves checkout tier and billing period', () {
    final monthly = AdRemovePlan.fromJson({
      'id': 'premium-monthly',
      'title': 'Monthly Ad-Free',
      'priceLabel': r'$4.99 / month',
      'sku': 'sub:premium:monthly',
    });
    final seasonal = AdRemovePlan.fromJson({
      'id': 'premium-seasonal',
      'title': 'Seasonal Ad-Free',
      'priceLabel': r'$11.99 / season',
      'sku': 'sub:premium:seasonal',
    });

    expect(monthly.tier, 'premium');
    expect(monthly.billingPeriod, 'monthly');
    expect(seasonal.tier, 'premium');
    expect(seasonal.billingPeriod, 'seasonal');
  });
}
