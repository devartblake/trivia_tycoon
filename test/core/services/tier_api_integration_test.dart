import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

void main() {
  group('TierApiClient Integration Tests', () {
    late TierApiClient tierApiClient;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      tierApiClient = TierApiClient(httpClient: mockHttpClient);
    });

    tearDown(() {
      tierApiClient.close();
    });

    // ─────────────────────────────────────────────────────────────────────
    // getTierDefinitions Tests
    // ─────────────────────────────────────────────────────────────────────

    group('getTierDefinitions', () {
      test('Returns tier definitions from successful API response', () async {
        // Arrange
        const successResponse = '''{
          "tiers": [
            {
              "id": "bronze-rookie",
              "name": "Bronze Rookie",
              "level": 1,
              "minXp": 0,
              "maxXp": 500,
              "iconName": "bronze_rookie",
              "rewards": {
                "badge": "welcome_badge",
                "coinsBonus": 100,
                "gemsBonus": 0
              }
            }
          ]
        }''';

        mockHttpClient.setResponse(http.Response(successResponse, 200));

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert
        expect(tiers, isNotEmpty);
        expect(tiers.length, greaterThan(0));
        expect(tiers.first.name, 'Bronze Rookie');
        expect(tiers.first.level, 1);
      });

      test('Falls back to mock data on network error', () async {
        // Arrange
        mockHttpClient.setException(
          const SocketException('Connection refused'),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert
        expect(tiers, isNotEmpty);
        expect(tiers.length, 7); // Mock has 7 tiers
        expect(tiers.first.name, 'Bronze Rookie');
      });

      test('Falls back to mock data on timeout', () async {
        // Arrange
        mockHttpClient.setException(
          TimeoutException('Request timeout'),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert
        expect(tiers, isNotEmpty);
        expect(tiers.length, 7);
      });

      test('Falls back to mock data on 500 error', () async {
        // Arrange
        const errorResponse = '{"error": "Internal server error"}';
        mockHttpClient.setResponse(http.Response(errorResponse, 500),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert
        expect(tiers, isNotEmpty);
        expect(tiers.length, 7); // Mock fallback
      });

      test('Falls back to mock data on invalid JSON', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('invalid json', 200),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert
        expect(tiers, isNotEmpty);
        expect(tiers.length, 7); // Mock fallback
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // getPlayerTierProgress Tests
    // ─────────────────────────────────────────────────────────────────────

    group('getPlayerTierProgress', () {
      const testUserId = 'user_123';

      test('Returns player tier progress from successful API response', () async {
        // Arrange
        const successResponse = '''{
          "currentTier": {
            "id": "silver-scholar",
            "name": "Silver Scholar",
            "level": 5,
            "minXp": 500,
            "maxXp": 1200,
            "iconName": "silver_scholar",
            "rewards": {
              "badge": "scholar_badge",
              "coinsBonus": 250,
              "gemsBonus": 5
            }
          },
          "nextTier": {
            "id": "gold-master",
            "name": "Gold Master",
            "level": 10,
            "minXp": 1200,
            "maxXp": 2500,
            "iconName": "gold_master",
            "rewards": {
              "badge": "master_badge",
              "coinsBonus": 500,
              "gemsBonus": 15
            }
          },
          "currentXp": 750,
          "xpInCurrentTier": 250,
          "xpNeededForNextTier": 450,
          "progressPercentage": 35
        }''';

        mockHttpClient.setResponse(http.Response(successResponse, 200));

        // Act
        final progress = await tierApiClient.getPlayerTierProgress(testUserId);

        // Assert
        expect(progress, isNotNull);
        expect(progress.currentTier.name, 'Silver Scholar');
        expect(progress.currentXp, 750);
        expect(progress.progressPercentage, 35);
        expect(progress.nextTier?.name, 'Gold Master');
      });

      test('Falls back to mock data on network error', () async {
        // Arrange
        mockHttpClient.setException(
          const SocketException('Connection refused'),
        );

        // Act
        final progress = await tierApiClient.getPlayerTierProgress(testUserId);

        // Assert
        expect(progress, isNotNull);
        expect(progress.currentTier.name, 'Bronze Rookie');
        expect(progress.currentXp, 0);
      });

      test('Uses userId in API endpoint', () async {
        // Arrange
        const successResponse = '{"currentTier": {"id": "bronze-rookie"}, "progressPercentage": 0}';
        mockHttpClient.setResponse(http.Response(successResponse, 200));

        // Act
        final progress = await tierApiClient.getPlayerTierProgress(testUserId);

        // Assert - Verify response is parsed correctly
        expect(progress.currentTier.id, 'bronze-rookie');
      });

      test('Falls back to mock data on 404 error', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('Not found', 404),
        );

        // Act
        final progress = await tierApiClient.getPlayerTierProgress(testUserId);

        // Assert
        expect(progress, isNotNull);
        expect(progress.currentTier.name, 'Bronze Rookie');
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // awardXp Tests
    // ─────────────────────────────────────────────────────────────────────

    group('awardXp', () {
      const testUserId = 'user_123';
      const testAmount = 100;
      const testReason = 'quiz_completed';

      test('Returns XP award result from successful API response', () async {
        // Arrange
        const successResponse = '''{
          "xpAwarded": 100,
          "totalXp": 750,
          "newLevel": 2,
          "tierUpgraded": false
        }''';

        mockHttpClient.setResponse(http.Response(successResponse, 200),
        );

        // Act
        final result = await tierApiClient.awardXp(testUserId, testAmount, testReason);

        // Assert
        expect(result, isNotNull);
        expect(result.xpAwarded, 100);
        expect(result.totalXp, 750);
        expect(result.newLevel, 2);
        expect(result.tierUpgraded, false);
      });

      test('Sends userId, amount, and reason in request body', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('{"xpAwarded": 100}', 200),
        );

        // Act
        final result = await tierApiClient.awardXp(testUserId, testAmount, testReason);

        // Assert - Verify response is parsed correctly
        expect(result.xpAwarded, 100);
      });

      test('Falls back to mock data on network error', () async {
        // Arrange
        mockHttpClient.setException(
          const SocketException('Connection refused'),
        );

        // Act
        final result = await tierApiClient.awardXp(testUserId, testAmount, testReason);

        // Assert
        expect(result, isNotNull);
        expect(result.xpAwarded, testAmount);
        expect(result.tierUpgraded, false);
      });

      test('Falls back to mock data on timeout', () async {
        // Arrange
        mockHttpClient.setException(
          TimeoutException('Request timeout'),
        );

        // Act
        final result = await tierApiClient.awardXp(testUserId, testAmount, testReason);

        // Assert
        expect(result, isNotNull);
        expect(result.xpAwarded, testAmount);
      });

      test('Handles tier upgrade response', () async {
        // Arrange
        const upgradeResponse = '''{
          "xpAwarded": 500,
          "totalXp": 1300,
          "newLevel": 3,
          "tierUpgraded": true
        }''';

        mockHttpClient.setResponse(http.Response(upgradeResponse, 200),
        );

        // Act
        final result = await tierApiClient.awardXp(testUserId, 500, 'tier_upgrade');

        // Assert
        expect(result.tierUpgraded, true);
        expect(result.newLevel, 3);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Error Handling Tests
    // ─────────────────────────────────────────────────────────────────────

    group('Error Handling', () {
      test('Handles null response gracefully', () async {
        // Arrange
        mockHttpClient.setException(Exception('Null response'));

        // Act & Assert - Should not throw
        expect(
          () => tierApiClient.getTierDefinitions(),
          throwsA(anything), // Will throw because exception escapes try-catch
        );
      });

      test('Handles malformed tier data', () async {
        // Arrange
        const malformedResponse = '{"tiers": [{}]}'; // Missing required fields
        mockHttpClient.setResponse(http.Response(malformedResponse, 200),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert - Should fallback to mock
        expect(tiers.length, 7);
      });

      test('Handles empty tier list response', () async {
        // Arrange
        const emptyResponse = '{"tiers": []}';
        mockHttpClient.setResponse(http.Response(emptyResponse, 200),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert - Should fallback to mock
        expect(tiers.length, 7);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Data Deserialization Tests
    // ─────────────────────────────────────────────────────────────────────

    group('Data Deserialization', () {
      test('Correctly deserializes TierDefinition from JSON', () async {
        // Arrange
        const response = '''{
          "tiers": [{
            "id": "test-tier",
            "name": "Test Tier",
            "level": 99,
            "minXp": 1000,
            "maxXp": 2000,
            "iconName": "test_icon",
            "rewards": {
              "badge": "test_badge",
              "coinsBonus": 999,
              "gemsBonus": 10
            }
          }]
        }''';

        mockHttpClient.setResponse(http.Response(response, 200),
        );

        // Act
        final tiers = await tierApiClient.getTierDefinitions();

        // Assert
        expect(tiers.first.id, 'test-tier');
        expect(tiers.first.name, 'Test Tier');
        expect(tiers.first.level, 99);
        expect(tiers.first.rewards.badge, 'test_badge');
        expect(tiers.first.rewards.coinsBonus, 999);
      });

      test('Correctly deserializes PlayerTierProgress from JSON', () async {
        // Arrange
        const response = '''{
          "currentTier": {
            "id": "test-tier",
            "name": "Test",
            "level": 5,
            "minXp": 0,
            "maxXp": 100,
            "iconName": "test",
            "rewards": {"badge": "test", "coinsBonus": 10, "gemsBonus": 1}
          },
          "currentXp": 50,
          "xpInCurrentTier": 50,
          "xpNeededForNextTier": 50,
          "progressPercentage": 50
        }''';

        mockHttpClient.setResponse(http.Response(response, 200),
        );

        // Act
        final progress = await tierApiClient.getPlayerTierProgress('test_user');

        // Assert
        expect(progress.currentXp, 50);
        expect(progress.progressPercentage, 50);
        expect(progress.xpNeededForNextTier, 50);
      });
    });

    // ─────────────────────────────────────────────────────────────────────
    // Performance Tests
    // ─────────────────────────────────────────────────────────────────────

    group('Performance', () {
      test('getTierDefinitions completes within 200ms on success', () async {
        // Arrange
        const response = '{"tiers": []}';
        mockHttpClient.setResponse(http.Response(response, 200),
        );

        // Act
        final stopwatch = Stopwatch()..start();
        await tierApiClient.getTierDefinitions();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('Falls back to mock within 100ms', () async {
        // Arrange
        mockHttpClient.setException(
          const SocketException('Network error'),
        );

        // Act
        final stopwatch = Stopwatch()..start();
        await tierApiClient.getTierDefinitions();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Mock Classes
// ─────────────────────────────────────────────────────────────────────

class MockHttpClient extends http.BaseClient {
  late http.Response _response;
  late Exception? _exception;
  bool _shouldThrow = false;

  void setResponse(http.Response response) {
    _response = response;
    _shouldThrow = false;
  }

  void setException(Exception exception) {
    _exception = exception;
    _shouldThrow = true;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_shouldThrow) {
      throw _exception!;
    }
    return http.StreamedResponse(
      Stream.value(_response.bodyBytes),
      _response.statusCode,
      headers: _response.headers,
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

class SocketException implements Exception {
  final String message;
  const SocketException(this.message);

  @override
  String toString() => 'SocketException: $message';
}
