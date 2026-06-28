import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/models/spin_system_models.dart';

/// API client for spin wheel configuration and control
/// Handles:
/// - Segment configuration from backend
/// - Probability configuration
/// - Real-time probability adjustments
/// - Analytics and telemetry
class SpinWheelApiClient {
  final http.Client _httpClient;
  static const String _baseUrl = 'https://api.synaptixplay.com/api/v1';

  SpinWheelApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Get current wheel segments with operator-controlled configuration
  ///
  /// This includes:
  /// - Enabled/disabled status (controlled by operator)
  /// - Current probability values (may be adjusted for campaigns)
  /// - Temporary event configurations
  /// - Win limits per day/week
  /// - Cooldown settings
  Future<List<WheelSegment>> getSegments() async {
    try {
      final uri = Uri.parse('$_baseUrl/arcade/spin/segments');
      LogManager.debug('[SpinWheelAPI] Fetching segments from $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final segments = (data['segments'] as List<dynamic>)
            .map((e) => WheelSegment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        LogManager.debug(
          '[SpinWheelAPI] Loaded ${segments.length} segments',
        );
        return segments;
      } else {
        throw SpinWheelApiException(
          message: 'Failed to fetch segments',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      LogManager.error(
        '[SpinWheelAPI] Error fetching segments: $e',
        source: 'SpinWheelApiClient.getSegments',
        error: e,
      );
      rethrow;
    }
  }

  /// Get probability configuration from backend
  ///
  /// This includes:
  /// - Base probability distribution
  /// - User-based modifiers (level, streak, currency)
  /// - Time-based adjustments (weekends, events)
  /// - Pity timer settings
  /// - Jackpot cooldown configuration
  Future<ProbabilityConfig> getProbabilityConfig() async {
    try {
      final uri = Uri.parse('$_baseUrl/arcade/spin/probability-config');
      LogManager.debug('[SpinWheelAPI] Fetching probability config from $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final config = ProbabilityConfig.fromJson(data);

        LogManager.debug(
          '[SpinWheelAPI] Probability config loaded (version: ${config.version})',
        );
        return config;
      } else {
        throw SpinWheelApiException(
          message: 'Failed to fetch probability config',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      LogManager.error(
        '[SpinWheelAPI] Error fetching probability config: $e',
        source: 'SpinWheelApiClient.getProbabilityConfig',
        error: e,
      );
      rethrow;
    }
  }

  /// Get spin analytics for a time period
  ///
  /// Useful for:
  /// - Monitoring probability distribution accuracy
  /// - Detecting anomalies
  /// - Campaign performance tracking
  /// - Player engagement metrics
  Future<SpinAnalytics> getAnalytics({
    String period = '24h',
    String? segmentId,
  }) async {
    try {
      final queryParams = {
        'period': period,
        if (segmentId != null) 'segmentId': segmentId,
      };

      final uri = Uri.parse('$_baseUrl/arcade/spin/analytics')
          .replace(queryParameters: queryParams);

      LogManager.debug('[SpinWheelAPI] Fetching analytics from $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analytics = SpinAnalytics.fromJson(data);

        LogManager.debug(
          '[SpinWheelAPI] Analytics loaded: ${analytics.totalSpins} spins',
        );
        return analytics;
      } else {
        throw SpinWheelApiException(
          message: 'Failed to fetch analytics',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      LogManager.error(
        '[SpinWheelAPI] Error fetching analytics: $e',
        source: 'SpinWheelApiClient.getAnalytics',
        error: e,
      );
      rethrow;
    }
  }

  /// Log a spin result to backend for analytics
  Future<void> logSpinResult(SpinResult result) async {
    try {
      final uri = Uri.parse('$_baseUrl/arcade/spin/results');
      LogManager.debug('[SpinWheelAPI] Logging spin result to $uri');

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(result.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        LogManager.error(
          '[SpinWheelAPI] Failed to log spin result: ${response.statusCode}',
          source: 'SpinWheelApiClient.logSpinResult',
        );
      }
    } catch (e) {
      LogManager.error(
        '[SpinWheelAPI] Error logging spin result: $e',
        source: 'SpinWheelApiClient.logSpinResult',
        error: e,
      );
      // Don't rethrow - analytics failure shouldn't break the spin flow
    }
  }

  /// Claim a spin reward with server validation
  Future<ClaimRewardResponse> claimReward({
    required String userId,
    required String spinResultId,
    required String segmentId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/arcade/spin/claim');
      LogManager.debug('[SpinWheelAPI] Claiming reward from $uri');

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'spinResultId': spinResultId,
          'segmentId': segmentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final claimResponse = ClaimRewardResponse.fromJson(data);

        LogManager.debug(
          '[SpinWheelAPI] Reward claimed successfully',
        );
        return claimResponse;
      } else {
        throw SpinWheelApiException(
          message: 'Failed to claim reward',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      LogManager.error(
        '[SpinWheelAPI] Error claiming reward: $e',
        source: 'SpinWheelApiClient.claimReward',
        error: e,
      );
      rethrow;
    }
  }

  void close() {
    _httpClient.close();
  }
}

/// Configuration for probability calculation
class ProbabilityConfig {
  final String version;
  final DateTime lastUpdated;
  final BaseDistribution baseDistribution;
  final Map<String, Modifier> modifiers;
  final List<TimeBasedAdjustment> timeBasedAdjustments;

  ProbabilityConfig({
    required this.version,
    required this.lastUpdated,
    required this.baseDistribution,
    required this.modifiers,
    required this.timeBasedAdjustments,
  });

  factory ProbabilityConfig.fromJson(Map<String, dynamic> json) {
    return ProbabilityConfig(
      version: json['version'] ?? '1.0.0',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      baseDistribution: BaseDistribution.fromJson(
        json['baseDistribution'] ?? {},
      ),
      modifiers: (json['modifiers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Modifier.fromJson(value)),
          ) ??
          {},
      timeBasedAdjustments:
          ((json['timeBasedAdjustments'] as List<dynamic>?) ?? [])
              .map((e) => TimeBasedAdjustment.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastUpdated': lastUpdated.toIso8601String(),
        'baseDistribution': baseDistribution.toJson(),
        'modifiers': modifiers.map((k, v) => MapEntry(k, v.toJson())),
        'timeBasedAdjustments':
            timeBasedAdjustments.map((e) => e.toJson()).toList(),
      };
}

class BaseDistribution {
  final double jackpot;
  final double rare;
  final double uncommon;
  final double common;

  BaseDistribution({
    required this.jackpot,
    required this.rare,
    required this.uncommon,
    required this.common,
  });

  factory BaseDistribution.fromJson(Map<String, dynamic> json) {
    return BaseDistribution(
      jackpot: (json['jackpot'] ?? 0.02).toDouble(),
      rare: (json['rare'] ?? 0.08).toDouble(),
      uncommon: (json['uncommon'] ?? 0.30).toDouble(),
      common: (json['common'] ?? 0.60).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'jackpot': jackpot,
        'rare': rare,
        'uncommon': uncommon,
        'common': common,
      };
}

class Modifier {
  final bool enabled;
  final double multiplier;
  final double maxBonus;

  Modifier({
    required this.enabled,
    required this.multiplier,
    required this.maxBonus,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      enabled: json['enabled'] ?? true,
      multiplier: (json['multiplier'] ?? 0.0).toDouble(),
      maxBonus: (json['maxBonus'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'multiplier': multiplier,
        'maxBonus': maxBonus,
      };
}

class TimeBasedAdjustment {
  final String name;
  final List<String>? days;
  final DateTime? startDate;
  final DateTime? endDate;
  final double probabilityMultiplier;
  final bool active;

  TimeBasedAdjustment({
    required this.name,
    this.days,
    this.startDate,
    this.endDate,
    required this.probabilityMultiplier,
    required this.active,
  });

  factory TimeBasedAdjustment.fromJson(Map<String, dynamic> json) {
    return TimeBasedAdjustment(
      name: json['name'] ?? '',
      days: List<String>.from(json['days'] ?? []),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      probabilityMultiplier: (json['probabilityMultiplier'] ?? 1.0).toDouble(),
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'days': days,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'probabilityMultiplier': probabilityMultiplier,
        'active': active,
      };
}

class SpinAnalytics {
  final DateTime fromDate;
  final DateTime toDate;
  final int totalSpins;
  final Map<String, SegmentStats> segmentStats;
  final List<Anomaly> anomalies;

  SpinAnalytics({
    required this.fromDate,
    required this.toDate,
    required this.totalSpins,
    required this.segmentStats,
    required this.anomalies,
  });

  factory SpinAnalytics.fromJson(Map<String, dynamic> json) {
    return SpinAnalytics(
      fromDate: DateTime.parse(json['period']['from'] ?? DateTime.now().toIso8601String()),
      toDate: DateTime.parse(json['period']['to'] ?? DateTime.now().toIso8601String()),
      totalSpins: json['totalSpins'] ?? 0,
      segmentStats: (json['segmentStats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, SegmentStats.fromJson(value)),
          ) ??
          {},
      anomalies: ((json['anomalies'] as List<dynamic>?) ?? [])
          .map((e) => Anomaly.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': {
          'from': fromDate.toIso8601String(),
          'to': toDate.toIso8601String(),
        },
        'totalSpins': totalSpins,
        'segmentStats': segmentStats.map((k, v) => MapEntry(k, v.toJson())),
        'anomalies': anomalies.map((e) => e.toJson()).toList(),
      };
}

class SegmentStats {
  final int winsCount;
  final double winRate;
  final double expectedRate;
  final double variance;
  final int uniquePlayers;

  SegmentStats({
    required this.winsCount,
    required this.winRate,
    required this.expectedRate,
    required this.variance,
    required this.uniquePlayers,
  });

  factory SegmentStats.fromJson(Map<String, dynamic> json) {
    return SegmentStats(
      winsCount: json['winsCount'] ?? 0,
      winRate: (json['winRate'] ?? 0.0).toDouble(),
      expectedRate: (json['expectedRate'] ?? 0.0).toDouble(),
      variance: (json['variance'] ?? 0.0).toDouble(),
      uniquePlayers: json['uniquePlayers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'winsCount': winsCount,
        'winRate': winRate,
        'expectedRate': expectedRate,
        'variance': variance,
        'uniquePlayers': uniquePlayers,
      };
}

class Anomaly {
  final String type;
  final String segmentId;
  final String description;

  Anomaly({
    required this.type,
    required this.segmentId,
    required this.description,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      type: json['type'] ?? 'unknown',
      segmentId: json['segmentId'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'segmentId': segmentId,
        'description': description,
      };
}

class ClaimRewardResponse {
  final bool success;
  final int? coinsAwarded;
  final int? gemsAwarded;
  final String? message;
  final Map<String, dynamic>? metadata;

  ClaimRewardResponse({
    required this.success,
    this.coinsAwarded,
    this.gemsAwarded,
    this.message,
    this.metadata,
  });

  factory ClaimRewardResponse.fromJson(Map<String, dynamic> json) {
    return ClaimRewardResponse(
      success: json['success'] ?? false,
      coinsAwarded: json['coinsAwarded'],
      gemsAwarded: json['gemsAwarded'],
      message: json['message'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'coinsAwarded': coinsAwarded,
        'gemsAwarded': gemsAwarded,
        'message': message,
        'metadata': metadata,
      };
}

/// Custom exception for spin wheel API errors
class SpinWheelApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  SpinWheelApiException({
    required this.message,
    this.statusCode,
    this.body,
  });

  @override
  String toString() => 'SpinWheelApiException: $message (status: $statusCode)';
}
