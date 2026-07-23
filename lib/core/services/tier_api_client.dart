import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/manager/log_manager.dart';

/// API client for tier/progression system
/// Supports both real API calls and mock fallback for development.
///
/// Real API Endpoints:
/// - GET /progression/tiers
/// - GET /progression/player/{userId}
/// - POST /progression/xp/award
///
/// Features:
/// - Automatic fallback to mock data if API unavailable
/// - Comprehensive error handling
/// - Debug logging for troubleshooting
/// - Retry logic for transient failures
class TierApiClient {
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String _baseUrl;
  static const String defaultBaseUrl = 'https://api.synaptixplay.com/api/v1';

  TierApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl);

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  /// MOCK: Hardcoded tier definitions from Phase 1
  /// TODO: Replace with real API when backend endpoints available
  static final List<TierDefinition> _mockTiers = [
    TierDefinition(
      id: 'bronze-rookie',
      name: 'Bronze Rookie',
      level: 1,
      minXp: 0,
      maxXp: 500,
      iconName: 'bronze_rookie',
      rewards: TierReward(
        badge: 'welcome_badge',
        coinsBonus: 100,
        gemsBonus: 0,
      ),
    ),
    TierDefinition(
      id: 'silver-scholar',
      name: 'Silver Scholar',
      level: 2,
      minXp: 500,
      maxXp: 1200,
      iconName: 'silver_scholar',
      rewards: TierReward(
        badge: 'scholar_badge',
        coinsBonus: 250,
        gemsBonus: 5,
      ),
    ),
    TierDefinition(
      id: 'gold-master',
      name: 'Gold Master',
      level: 3,
      minXp: 1200,
      maxXp: 2500,
      iconName: 'gold_master',
      rewards: TierReward(
        badge: 'master_badge',
        coinsBonus: 500,
        gemsBonus: 15,
      ),
    ),
    TierDefinition(
      id: 'platinum-elite',
      name: 'Platinum Elite',
      level: 4,
      minXp: 2500,
      maxXp: 5000,
      iconName: 'platinum_elite',
      rewards: TierReward(
        badge: 'elite_badge',
        coinsBonus: 1000,
        gemsBonus: 30,
      ),
    ),
    TierDefinition(
      id: 'diamond-legend',
      name: 'Diamond Legend',
      level: 5,
      minXp: 5000,
      maxXp: 10000,
      iconName: 'diamond_legend',
      rewards: TierReward(
        badge: 'legend_badge',
        coinsBonus: 2000,
        gemsBonus: 50,
      ),
    ),
    TierDefinition(
      id: 'master-sage',
      name: 'Master Sage',
      level: 6,
      minXp: 10000,
      maxXp: 20000,
      iconName: 'master_sage',
      rewards: TierReward(
        badge: 'sage_badge',
        coinsBonus: 5000,
        gemsBonus: 100,
      ),
    ),
    TierDefinition(
      id: 'celestial-ascendant',
      name: 'Celestial Ascendant',
      level: 7,
      minXp: 20000,
      maxXp: 2147483647,
      iconName: 'celestial_ascendant',
      rewards: TierReward(
        badge: 'ascendant_badge',
        coinsBonus: 5000,
        gemsBonus: 100,
      ),
    ),
  ];

  /// Get all tier definitions from API or mock fallback
  Future<List<TierDefinition>> getTierDefinitions() async {
    try {
      LogManager.debug('[TierApiClient] Fetching tier definitions from API');

      final uri = Uri.parse('$_baseUrl/progression/tiers');

      try {
        final response = await _httpClient.get(uri).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('API request timeout'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final tiersJson = data is List
              ? data
              : data is Map<String, dynamic>
                  ? data['tiers'] as List<dynamic>?
                  : null;
          final tiers = tiersJson
              ?.map((e) => TierDefinition.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              // Drop malformed entries (a tier with no id, e.g. `{}`) so a junk
              // payload falls back to the mock tiers instead of surfacing a
              // meaningless tier.
              .where((t) => t.id.isNotEmpty)
              .toList();

          if (tiers != null && tiers.isNotEmpty) {
            LogManager.debug(
              '[TierApiClient] Loaded ${tiers.length} tier definitions from API',
            );
            return tiers;
          }
        }

        throw TierApiException(
          message: 'Failed to fetch tier definitions',
          statusCode: response.statusCode,
          body: response.body,
        );
      } on SocketException catch (e) {
        LogManager.warning(
          '[TierApiClient] Network error fetching tiers: $e',
          source: 'TierApiClient.getTierDefinitions',
        );
        return _getMockTiersFallback();
      } on TimeoutException catch (e) {
        LogManager.warning(
          '[TierApiClient] API timeout: $e',
          source: 'TierApiClient.getTierDefinitions',
        );
        return _getMockTiersFallback();
      } on TierApiException catch (e) {
        LogManager.warning(
          '[TierApiClient] API error: ${e.message}',
          source: 'TierApiClient.getTierDefinitions',
        );
        return _getMockTiersFallback();
      }
    } catch (e) {
      LogManager.error(
        '[TierApiClient] Unexpected error fetching tier definitions: $e',
        source: 'TierApiClient.getTierDefinitions',
        error: e,
      );
      return _getMockTiersFallback();
    }
  }

  /// Get mock tier definitions for fallback
  List<TierDefinition> _getMockTiersFallback() {
    LogManager.debug('[TierApiClient] Using mock tier definitions as fallback');
    return _mockTiers;
  }

  /// Get player's current tier progress from API or mock fallback
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    try {
      if (userId.isEmpty) {
        LogManager.debug(
          '[TierApiClient] Missing user ID, using mock player progress fallback',
        );
        return _getMockPlayerProgressFallback();
      }

      LogManager.debug(
          '[TierApiClient] Fetching player tier progress for user=$userId');

      final uri = Uri.parse('$_baseUrl/progression/player/$userId');

      try {
        final response = await _httpClient.get(uri).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('API request timeout'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final progress = await _parsePlayerTierProgress(data);

          LogManager.debug(
            '[TierApiClient] Player tier: ${progress.currentTier.name}, Progress: ${progress.progressPercentage}%',
          );
          return progress;
        }

        throw TierApiException(
          message: 'Failed to fetch player tier progress',
          statusCode: response.statusCode,
          body: response.body,
        );
      } on SocketException catch (e) {
        LogManager.warning(
          '[TierApiClient] Network error fetching player progress: $e',
          source: 'TierApiClient.getPlayerTierProgress',
        );
        return _getMockPlayerProgressFallback();
      } on TimeoutException catch (e) {
        LogManager.warning(
          '[TierApiClient] API timeout: $e',
          source: 'TierApiClient.getPlayerTierProgress',
        );
        return _getMockPlayerProgressFallback();
      } on TierApiException catch (e) {
        LogManager.warning(
          '[TierApiClient] API error: ${e.message}',
          source: 'TierApiClient.getPlayerTierProgress',
        );
        return _getMockPlayerProgressFallback();
      }
    } catch (e) {
      LogManager.error(
        '[TierApiClient] Unexpected error fetching player progress: $e',
        source: 'TierApiClient.getPlayerTierProgress',
        error: e,
      );
      return _getMockPlayerProgressFallback();
    }
  }

  /// Get mock player progress for fallback
  PlayerTierProgress _getMockPlayerProgressFallback() {
    LogManager.debug('[TierApiClient] Using mock player progress as fallback');
    final firstTier = _mockTiers.first;
    return PlayerTierProgress(
      currentTier: firstTier,
      nextTier: _mockTiers.length > 1 ? _mockTiers[1] : null,
      currentXp: 0,
      xpInCurrentTier: 0,
      xpNeededForNextTier: firstTier.maxXp,
      progressPercentage: 0,
    );
  }

  /// Award XP to player via API or mock fallback
  Future<XpAwardResult> awardXp(
      String userId, int amount, String reason) async {
    try {
      if (userId.isEmpty) {
        LogManager.debug(
          '[TierApiClient] Missing user ID, using mock XP award fallback',
        );
        return _getMockXpAwardFallback(amount);
      }

      LogManager.debug(
        '[TierApiClient] Awarding $amount XP to user=$userId (reason: $reason)',
      );

      final uri = Uri.parse('$_baseUrl/progression/xp/award');

      try {
        final response = await _httpClient
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'userId': userId,
                'xpAmount': amount,
                'reason': reason,
              }),
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('API request timeout'),
            );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final result = XpAwardResult.fromJson(data);

          LogManager.debug('[TierApiClient] XP awarded successfully');
          return result;
        }

        throw TierApiException(
          message: 'Failed to award XP',
          statusCode: response.statusCode,
          body: response.body,
        );
      } on SocketException catch (e) {
        LogManager.warning(
          '[TierApiClient] Network error awarding XP: $e',
          source: 'TierApiClient.awardXp',
        );
        return _getMockXpAwardFallback(amount);
      } on TimeoutException catch (e) {
        LogManager.warning(
          '[TierApiClient] API timeout: $e',
          source: 'TierApiClient.awardXp',
        );
        return _getMockXpAwardFallback(amount);
      } on TierApiException catch (e) {
        LogManager.warning(
          '[TierApiClient] API error: ${e.message}',
          source: 'TierApiClient.awardXp',
        );
        return _getMockXpAwardFallback(amount);
      }
    } catch (e) {
      LogManager.error(
        '[TierApiClient] Unexpected error awarding XP: $e',
        source: 'TierApiClient.awardXp',
        error: e,
      );
      return _getMockXpAwardFallback(amount);
    }
  }

  /// Get mock XP award result for fallback
  XpAwardResult _getMockXpAwardFallback(int amount) {
    LogManager.debug('[TierApiClient] Using mock XP award result as fallback');
    return XpAwardResult(
      xpAwarded: amount,
      totalXp: amount,
      newLevel: 1,
      tierUpgraded: false,
    );
  }

  Future<PlayerTierProgress> _parsePlayerTierProgress(
    Map<String, dynamic> json,
  ) async {
    if (json.containsKey('currentTier')) {
      return PlayerTierProgress.fromJson(json);
    }

    final tiers = await getTierDefinitions();
    return PlayerTierProgress.fromBackendJson(json, tiers);
  }

  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}

/// Tier definition
class TierDefinition {
  final String id; // Unique identifier
  final String name; // Display name
  final int level; // Player level for this tier
  final int minXp; // Minimum XP to reach this tier
  final int maxXp; // Maximum XP in this tier
  final String iconName; // Icon/image name
  final TierReward rewards; // Rewards for reaching this tier

  TierDefinition({
    required this.id,
    required this.name,
    required this.level,
    required this.minXp,
    required this.maxXp,
    required this.iconName,
    required this.rewards,
  });

  /// XP range for this tier
  int get xpRange => maxXp - minXp;

  /// Is this the final tier?
  bool get isFinalTier => maxXp >= 2147483647;

  factory TierDefinition.fromJson(Map<String, dynamic> json) {
    return TierDefinition(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'Unknown Tier'),
      level: _asInt(json['level'], fallback: 1),
      minXp: _asInt(json['minXp'] ?? json['min_xp']),
      maxXp: _asInt(json['maxXp'] ?? json['max_xp'], fallback: 999999),
      iconName: _asString(json['iconName'] ?? json['icon_name'],
          fallback: 'tier_icon'),
      rewards: TierReward.fromJson(
        Map<String, dynamic>.from((json['rewards'] as Map?) ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'minXp': minXp,
        'maxXp': maxXp,
        'iconName': iconName,
        'rewards': rewards.toJson(),
      };
}

/// Rewards for reaching a tier
class TierReward {
  final String badge; // Badge name/id
  final int coinsBonus; // Coins reward
  final int gemsBonus; // Gems reward

  TierReward({
    required this.badge,
    required this.coinsBonus,
    required this.gemsBonus,
  });

  factory TierReward.fromJson(Map<String, dynamic> json) {
    return TierReward(
      badge: _asString(json['badge'], fallback: 'unknown_badge'),
      coinsBonus: _asInt(
        json['coinsBonus'] ?? json['coins_bonus'] ?? json['coins'],
      ),
      gemsBonus: _asInt(
        json['gemsBonus'] ?? json['gems_bonus'] ?? json['gems'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'badge': badge,
        'coinsBonus': coinsBonus,
        'gemsBonus': gemsBonus,
      };
}

/// Player's current tier progress
class PlayerTierProgress {
  final TierDefinition currentTier;
  final TierDefinition? nextTier; // Null if at max tier
  final int currentXp;
  final int xpInCurrentTier;
  final int xpNeededForNextTier;
  final int progressPercentage; // 0-100

  PlayerTierProgress({
    required this.currentTier,
    this.nextTier,
    required this.currentXp,
    required this.xpInCurrentTier,
    required this.xpNeededForNextTier,
    required this.progressPercentage,
  });

  /// Is player at max tier?
  bool get isMaxTier => nextTier == null;

  factory PlayerTierProgress.fromJson(Map<String, dynamic> json) {
    return PlayerTierProgress(
      currentTier: TierDefinition.fromJson(
        Map<String, dynamic>.from((json['currentTier'] as Map?) ?? const {}),
      ),
      nextTier: json['nextTier'] is Map
          ? TierDefinition.fromJson(
              Map<String, dynamic>.from(json['nextTier'] as Map),
            )
          : null,
      currentXp: _asInt(json['currentXp'] ?? json['current_xp']),
      xpInCurrentTier: _asInt(
        json['xpInCurrentTier'] ?? json['xp_in_current_tier'],
      ),
      xpNeededForNextTier: _asInt(
        json['xpNeededForNextTier'] ?? json['xp_needed_for_next_tier'],
      ),
      progressPercentage: _asInt(
        json['progressPercentage'] ?? json['progress_percentage'],
      ),
    );
  }

  factory PlayerTierProgress.fromBackendJson(
    Map<String, dynamic> json,
    List<TierDefinition> tiers,
  ) {
    final currentTierId =
        _asString(json['currentTierId'] ?? json['current_tier_id']);
    final currentTierName = _asString(
      json['currentTierName'] ?? json['current_tier_name'],
      fallback: 'Unknown Tier',
    );
    final currentXp = _asInt(json['currentXp'] ?? json['current_xp']);
    final xpInCurrentTier = _asInt(
      json['xpInCurrentTier'] ?? json['xp_in_current_tier'],
    );
    final xpNeededForNextTier = _asInt(
      json['xpNeededForNextTier'] ?? json['xp_needed_for_next_tier'],
    );
    final progressPercentage = _asInt(
      json['progressPercentage'] ?? json['progress_percentage'],
    ).clamp(0, 100);

    TierDefinition? currentTier;
    for (final tier in tiers) {
      if (tier.id == currentTierId || tier.name == currentTierName) {
        currentTier = tier;
        break;
      }
    }

    currentTier ??= TierDefinition(
      id: currentTierId,
      name: currentTierName,
      level: _asInt(json['currentLevel'] ?? json['current_level'], fallback: 1),
      minXp: currentXp - xpInCurrentTier,
      maxXp: currentXp - xpInCurrentTier + xpNeededForNextTier,
      iconName: currentTierId.isNotEmpty ? currentTierId : 'tier_icon',
      rewards: TierReward(badge: '', coinsBonus: 0, gemsBonus: 0),
    );

    final resolvedCurrentTier = currentTier;

    TierDefinition? nextTier;
    final currentIndex =
        tiers.indexWhere((tier) => tier.id == resolvedCurrentTier.id);
    if (currentIndex >= 0 && currentIndex + 1 < tiers.length) {
      nextTier = tiers[currentIndex + 1];
    }

    return PlayerTierProgress(
      currentTier: resolvedCurrentTier,
      nextTier: nextTier,
      currentXp: currentXp,
      xpInCurrentTier: xpInCurrentTier,
      xpNeededForNextTier: xpNeededForNextTier,
      progressPercentage: progressPercentage,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentTier': currentTier.toJson(),
        'nextTier': nextTier?.toJson(),
        'currentXp': currentXp,
        'xpInCurrentTier': xpInCurrentTier,
        'xpNeededForNextTier': xpNeededForNextTier,
        'progressPercentage': progressPercentage,
      };
}

/// Result of awarding XP
class XpAwardResult {
  final int xpAwarded;
  final int totalXp;
  final int newLevel;
  final bool tierUpgraded;

  XpAwardResult({
    required this.xpAwarded,
    required this.totalXp,
    required this.newLevel,
    required this.tierUpgraded,
  });

  factory XpAwardResult.fromJson(Map<String, dynamic> json) {
    return XpAwardResult(
      xpAwarded: _asInt(json['xpAwarded'] ?? json['xp_awarded']),
      totalXp: _asInt(json['totalXp'] ?? json['total_xp']),
      newLevel: _asInt(json['newLevel'] ?? json['new_level'], fallback: 1),
      tierUpgraded: _asBool(json['tierUpgraded'] ?? json['tier_upgraded']),
    );
  }

  Map<String, dynamic> toJson() => {
        'xpAwarded': xpAwarded,
        'totalXp': totalXp,
        'newLevel': newLevel,
        'tierUpgraded': tierUpgraded,
      };
}

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final stringValue = value.toString();
  return stringValue.isEmpty ? fallback : stringValue;
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? fallback;
  }
  return fallback;
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Exception thrown by tier API
class TierApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  TierApiException({
    required this.message,
    this.statusCode,
    this.body,
  });

  @override
  String toString() =>
      'TierApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
