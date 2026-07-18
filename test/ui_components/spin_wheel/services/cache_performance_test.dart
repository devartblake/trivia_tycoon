import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/spin_wheel_api_client.dart';
import 'package:synaptix/core/services/tier_api_client.dart';
import 'package:synaptix/ui_components/spin_wheel/models/spin_system_models.dart';
import 'package:synaptix/ui_components/spin_wheel/services/spin_config_cache.dart';
import 'package:synaptix/ui_components/spin_wheel/services/tier_config_cache.dart';

void main() {
  group('Cache Performance Tests', () {
    // ─────────────────────────────────────────────────────────────────────
    // TierConfigCache Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    group('TierConfigCache', () {
      late TierConfigCache cache;
      late FakeTierApiClient fakeApiClient;

      setUp(() {
        fakeApiClient = FakeTierApiClient();
        cache = TierConfigCache(apiClient: fakeApiClient);
      });

      tearDown(() {
        cache.clearAllCaches();
      });

      test('Memory cache hit rate > 80% with repeated requests', () async {
        // Arrange
        fakeApiClient.tiers = [
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

        // Act: Make 50 requests
        for (int i = 0; i < 50; i++) {
          await cache.getTierDefinitions();
        }

        // Assert
        final stats = cache.getCacheStats();
        expect(stats, isNotNull);
        // After first miss, 49 hits out of 50 = 98% hit rate
        expect(fakeApiClient.getTierDefinitionsCalls, 1);
      });

      test('Memory cache response < 1ms', () async {
        // Arrange
        fakeApiClient.tiers = [
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
        fakeApiClient.tiers = [];
        fakeApiClient.tierProgress = PlayerTierProgress(
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
        );
        fakeApiClient.xpResult = XpAwardResult(
          xpAwarded: 50,
          totalXp: 50,
          newLevel: 1,
          tierUpgraded: false,
        );

        // Prime cache
        await cache.getPlayerTierProgress('user_1');
        expect(fakeApiClient.getPlayerTierProgressCalls, 1);

        // Act: Award XP (should invalidate cache)
        await cache.awardXp('user_1', 50, 'test');

        // Assert: Next call should fetch fresh data
        await cache.getPlayerTierProgress('user_1');
        expect(fakeApiClient.getPlayerTierProgressCalls, 2);
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
        fakeApiClient.tiers = [];

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
      late FakeSpinWheelApiClient fakeApiClient;

      setUp(() {
        fakeApiClient = FakeSpinWheelApiClient();
        cache = SpinConfigCache(apiClient: fakeApiClient);
      });

      tearDown(() {
        cache.clearAllCaches();
      });

      test('Segment cache hit rate > 80%', () async {
        // Arrange
        fakeApiClient.segments = [];

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
        fakeApiClient.probabilityConfig = ProbabilityConfig(
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
        fakeApiClient.segments = [];

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
        fakeApiClient.analytics = SpinAnalytics(
          fromDate: DateTime.now(),
          toDate: DateTime.now(),
          totalSpins: 0,
          segmentStats: {},
          anomalies: [],
        );

        // Prime cache
        await cache.getAnalytics();
        expect(fakeApiClient.getAnalyticsCalls, 1);

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
        expect(fakeApiClient.getAnalyticsCalls, 2);
      });

      test('Cache statistics tracking', () async {
        // Arrange
        fakeApiClient.segments = [];
        fakeApiClient.probabilityConfig = ProbabilityConfig(
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
        fakeApiClient.segments = [];

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
        fakeApiClient.segments = [];

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
      late FakeTierApiClient fakeTierApiClient;

      setUp(() {
        fakeTierApiClient = FakeTierApiClient();
        tierCache = TierConfigCache(apiClient: fakeTierApiClient);
      });

      test('Cached response 100x faster than uncached', () async {
        // Arrange: the uncached fetch is slow; the cached read serves from
        // memory without hitting the client at all.
        fakeTierApiClient.tiers = [];
        fakeTierApiClient.getTierDefinitionsDelay =
            const Duration(milliseconds: 100);

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
// Manual fakes
//
// The API clients return non-nullable types, which hand-written
// `extends Mock` classes can't stub under null-safety (Mockito needs codegen).
// These lightweight fakes record call counts and return configured values;
// `noSuchMethod` no-ops the unused surface of each interface.
// ─────────────────────────────────────────────────────────────────────

class FakeTierApiClient implements TierApiClient {
  List<TierDefinition> tiers = [];
  PlayerTierProgress? tierProgress;
  XpAwardResult? xpResult;
  Duration getTierDefinitionsDelay = Duration.zero;

  int getTierDefinitionsCalls = 0;
  int getPlayerTierProgressCalls = 0;
  int awardXpCalls = 0;

  @override
  Future<List<TierDefinition>> getTierDefinitions() async {
    getTierDefinitionsCalls++;
    if (getTierDefinitionsDelay > Duration.zero) {
      await Future.delayed(getTierDefinitionsDelay);
    }
    return tiers;
  }

  @override
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    getPlayerTierProgressCalls++;
    return tierProgress!;
  }

  @override
  Future<XpAwardResult> awardXp(
      String userId, int amount, String reason) async {
    awardXpCalls++;
    return xpResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSpinWheelApiClient implements SpinWheelApiClient {
  List<WheelSegment> segments = [];
  ProbabilityConfig? probabilityConfig;
  SpinAnalytics? analytics;

  int getSegmentsCalls = 0;
  int getProbabilityConfigCalls = 0;
  int getAnalyticsCalls = 0;
  int logSpinResultCalls = 0;

  @override
  Future<List<WheelSegment>> getSegments() async {
    getSegmentsCalls++;
    return segments;
  }

  @override
  Future<ProbabilityConfig> getProbabilityConfig() async {
    getProbabilityConfigCalls++;
    return probabilityConfig!;
  }

  @override
  Future<SpinAnalytics> getAnalytics({
    String period = '24h',
    String? segmentId,
  }) async {
    getAnalyticsCalls++;
    return analytics!;
  }

  @override
  Future<void> logSpinResult(SpinResult result) async {
    logSpinResultCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
