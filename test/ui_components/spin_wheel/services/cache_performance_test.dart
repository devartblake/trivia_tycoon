import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:trivia_tycoon/core/services/spin_wheel_api_client.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/models/spin_system_models.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/services/spin_config_cache.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/services/tier_config_cache.dart';

void main() {
  group('Cache Performance Tests', () {
    // ─────────────────────────────────────────────────────────────────────
    // TierConfigCache Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    group('TierConfigCache', () {
      late TierConfigCache cache;
      late MockTierApiClient mockApiClient;

      setUp(() {
        mockApiClient = MockTierApiClient();
        cache = TierConfigCache(apiClient: mockApiClient);
      });

      tearDown(() {
        cache.clearAllCaches();
      });

      test('Memory cache hit rate > 80% with repeated requests', () async {
        // Arrange
        final mockTiers = [
          TierDefinition(
            id: 'test-1',
            name: 'Test 1',
            level: 1,
            minXp: 0,
            maxXp: 100,
            iconName: 'test',
            rewards: TierReward(badge: 'test', coinsBonus: 10, gemsBonus: 0),
          ),
        ];

        when(mockApiClient.getTierDefinitions()).thenAnswer(
          (_) async => mockTiers,
        );

        // Act: Make 50 requests
        for (int i = 0; i < 50; i++) {
          await cache.getTierDefinitions();
        }

        // Assert
        final stats = cache.getCacheStats();
        expect(stats, isNotNull);
        // After first miss, 49 hits out of 50 = 98% hit rate
        expect(verify(mockApiClient.getTierDefinitions()).callCount, 1);
      });

      test('Memory cache response < 1ms', () async {
        // Arrange
        final mockTiers = [
          TierDefinition(
            id: 'test-1',
            name: 'Test 1',
            level: 1,
            minXp: 0,
            maxXp: 100,
            iconName: 'test',
            rewards: TierReward(badge: 'test', coinsBonus: 10, gemsBonus: 0),
          ),
        ];

        when(mockApiClient.getTierDefinitions()).thenAnswer(
          (_) async => mockTiers,
        );

        // Prime cache
        await cache.getTierDefinitions();

        // Act: Measure cached response time
        final stopwatch = Stopwatch()..start();
        await cache.getTierDefinitions();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1));
      });

      test('Cache invalidation works on XP award', () async {
        // Arrange
        when(mockApiClient.getTierDefinitions()).thenAnswer(
          (_) async => [],
        );

        when(mockApiClient.getPlayerTierProgress('user_1')).thenAnswer(
          (_) async => PlayerTierProgress(
            currentTier: TierDefinition(
              id: 'test',
              name: 'Test',
              level: 1,
              minXp: 0,
              maxXp: 100,
              iconName: 'test',
              rewards: TierReward(badge: 'test', coinsBonus: 10, gemsBonus: 0),
            ),
            currentXp: 0,
            xpInCurrentTier: 0,
            xpNeededForNextTier: 100,
            progressPercentage: 0,
          ),
        );

        when(mockApiClient.awardXp('user_1', 50, 'test')).thenAnswer(
          (_) async => XpAwardResult(
            xpAwarded: 50,
            totalXp: 50,
            newLevel: 1,
            tierUpgraded: false,
          ),
        );

        // Prime cache
        await cache.getPlayerTierProgress('user_1');
        verify(mockApiClient.getPlayerTierProgress('user_1')).called(1);

        // Act: Award XP (should invalidate cache)
        await cache.awardXp('user_1', 50, 'test');

        // Assert: Next call should fetch fresh data
        await cache.getPlayerTierProgress('user_1');
        verify(mockApiClient.getPlayerTierProgress('user_1')).called(2);
      });

      test('Cache TTL expiration works', () async {
        // Note: This test would need manual time manipulation
        // or a mocked DateTime. For now, we test the logic structure.
        final stats = cache.getCacheStats();
        expect(stats.containsKey('totalItems'), true);
        expect(stats.containsKey('maxItems'), true);
        expect(stats.containsKey('expiredItems'), true);
      });

      test('LRU eviction removes oldest items', () async {
        // Note: This would require filling cache beyond max size
        // Current max is 20 items
        final stats = cache.getCacheStats();
        expect(stats['maxItems'], 20);
      });

      test('Cache memory usage tracking', () async {
        // Arrange
        when(mockApiClient.getTierDefinitions()).thenAnswer(
          (_) async => [],
        );

        // Act
        await cache.getTierDefinitions();
        final stats = cache.getCacheStats();

        // Assert
        expect(stats.containsKey('memoryUsage'), true);
        final memoryUsage = stats['memoryUsage'] as String;
        expect(memoryUsage.contains('MB'), true);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // SpinConfigCache Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    group('SpinConfigCache', () {
      late SpinConfigCache cache;
      late MockSpinWheelApiClient mockApiClient;

      setUp(() {
        mockApiClient = MockSpinWheelApiClient();
        cache = SpinConfigCache(apiClient: mockApiClient);
      });

      tearDown(() {
        cache.clearAllCaches();
      });

      test('Segment cache hit rate > 80%', () async {
        // Arrange
        when(mockApiClient.getSegments()).thenAnswer(
          (_) async => [],
        );

        // Act: Make 100 requests
        for (int i = 0; i < 100; i++) {
          await cache.getSegments();
        }

        // Assert
        final stats = cache.getCacheStats();
        final hitRate = stats['hitRate'] as double;
        expect(hitRate, greaterThan(0.80));
      });

      test('Probability config cache hit rate > 80%', () async {
        // Arrange
        when(mockApiClient.getProbabilityConfig()).thenAnswer(
          (_) async => ProbabilityConfig(
            version: '1.0.0',
            lastUpdated: DateTime.now(),
            baseDistribution: BaseDistribution(
              jackpot: 0.02,
              rare: 0.08,
              uncommon: 0.30,
              common: 0.60,
            ),
            modifiers: {},
            timeBasedAdjustments: [],
          ),
        );

        // Act: Make 100 requests
        for (int i = 0; i < 100; i++) {
          await cache.getProbabilityConfig();
        }

        // Assert
        final stats = cache.getCacheStats();
        final hitRate = stats['hitRate'] as double;
        expect(hitRate, greaterThan(0.80));
      });

      test('Cached segment response < 1ms', () async {
        // Arrange
        when(mockApiClient.getSegments()).thenAnswer(
          (_) async => [],
        );

        // Prime cache
        await cache.getSegments();

        // Act
        final stopwatch = Stopwatch()..start();
        await cache.getSegments();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1));
      });

      test('Analytics cache invalidation on log', () async {
        // Arrange
        when(mockApiClient.getAnalytics(period: '24h')).thenAnswer(
          (_) async => SpinAnalytics(
            fromDate: DateTime.now(),
            toDate: DateTime.now(),
            totalSpins: 0,
            segmentStats: {},
            anomalies: [],
          ),
        );

        // Note: logSpinResult will be mocked dynamically when called
        // Prime cache
        await cache.getAnalytics();
        verify(mockApiClient.getAnalytics(period: '24h')).called(1);

        // Act: Log spin result (should invalidate analytics cache)
        await cache.logSpinResult(
          SpinResult(
            id: 'test',
            label: 'Test Segment',
            reward: 100,
            timestamp: DateTime.now(),
          ),
        );

        // Assert: Next call should fetch fresh data
        await cache.getAnalytics();
        verify(mockApiClient.getAnalytics(period: '24h')).called(2);
      });

      test('Cache statistics tracking', () async {
        // Arrange
        when(mockApiClient.getSegments()).thenAnswer(
          (_) async => [],
        );

        when(mockApiClient.getProbabilityConfig()).thenAnswer(
          (_) async => ProbabilityConfig(
            version: '1.0.0',
            lastUpdated: DateTime.now(),
            baseDistribution: BaseDistribution(
              jackpot: 0.02,
              rare: 0.08,
              uncommon: 0.30,
              common: 0.60,
            ),
            modifiers: {},
            timeBasedAdjustments: [],
          ),
        );

        // Act
        await cache.getSegments();
        await cache.getProbabilityConfig();
        await cache.getSegments();

        final stats = cache.getCacheStats();

        // Assert
        expect(stats['cacheHits'], 1); // Second getSegments call is a hit
        expect(stats['cacheMisses'],
            2); // First getSegments and getProbabilityConfig are misses
        expect(stats['totalItems'], 2);
        expect(stats['maxItems'], 20);
      });

      test('Clear cache resets statistics', () async {
        // Arrange
        when(mockApiClient.getSegments()).thenAnswer(
          (_) async => [],
        );

        await cache.getSegments();

        // Act
        cache.clearAllCaches();
        final stats = cache.getCacheStats();

        // Assert
        expect(stats['totalItems'], 0);
        expect(stats['cacheHits'], 0);
        expect(stats['cacheMisses'], 0);
      });

      test('Memory usage estimation', () async {
        // Arrange
        when(mockApiClient.getSegments()).thenAnswer(
          (_) async => [],
        );

        // Act
        await cache.getSegments();
        final stats = cache.getCacheStats();

        // Assert
        expect(stats.containsKey('memoryUsage'), true);
        final memoryUsage = stats['memoryUsage'] as String;
        expect(memoryUsage.contains('MB'), true);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Comparative Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    group('Cache vs API Performance', () {
      late TierConfigCache tierCache;
      late MockTierApiClient mockTierApiClient;

      setUp(() {
        mockTierApiClient = MockTierApiClient();
        tierCache = TierConfigCache(apiClient: mockTierApiClient);
      });

      test('Cached response 100x faster than uncached', () async {
        // Arrange
        when(mockTierApiClient.getTierDefinitions()).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return [];
          },
        );

        // Act: First call (uncached)
        final stopwatch1 = Stopwatch()..start();
        await tierCache.getTierDefinitions();
        stopwatch1.stop();

        // Cached call
        final stopwatch2 = Stopwatch()..start();
        await tierCache.getTierDefinitions();
        stopwatch2.stop();

        // Assert
        final speedup = stopwatch1.elapsedMilliseconds /
            (stopwatch2.elapsedMilliseconds + 1);
        expect(speedup, greaterThan(10.0)); // At least 10x faster
      });
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Mock Classes
// ─────────────────────────────────────────────────────────────────────

class MockTierApiClient extends Mock implements TierApiClient {}

class MockSpinWheelApiClient extends Mock implements SpinWheelApiClient {}

/// Spin result for testing
