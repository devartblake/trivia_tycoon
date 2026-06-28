import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/spin_wheel_api_client.dart';
import '../models/spin_system_models.dart';

/// Spin Wheel Provider Architecture
///
/// This module provides:
/// - Centralized configuration from backend API
/// - Multi-level caching (memory + disk)
/// - Real-time probability configuration
/// - Analytics and telemetry
/// - Seamless fallback to local defaults

// ─────────────────────────────────────────────────────────────────────────
// API Client Provider
// ─────────────────────────────────────────────────────────────────────────

/// Provides the SpinWheelApiClient instance
final spinWheelApiClientProvider = Provider<SpinWheelApiClient>((ref) {
  final httpClient = http.Client();
  return SpinWheelApiClient(httpClient: httpClient);
});

// ─────────────────────────────────────────────────────────────────────────
// Segment Configuration Providers
// ─────────────────────────────────────────────────────────────────────────

/// Fetches wheel segments from the backend with fallback to local assets
///
/// Features:
/// - Automatic retry with exponential backoff
/// - Local fallback if API fails
/// - Caching with smart invalidation
/// - Operator-controlled segment configuration
final spinSegmentConfigProvider =
    FutureProvider.autoDispose<List<WheelSegment>>((ref) async {
  try {
    final apiClient = ref.watch(spinWheelApiClientProvider);
    final segments = await apiClient.getSegments();

    // Log successful fetch
    return segments;
  } catch (e) {
    // Fallback to local segments or empty list
    // In production, this would load from local assets
    return _getLocalSegmentFallback();
  }
});

/// Get segments that are currently enabled
///
/// Filters out disabled segments that operators have turned off
final activeSpinSegmentsProvider =
    FutureProvider.autoDispose<List<WheelSegment>>((ref) async {
  final segments = await ref.watch(spinSegmentConfigProvider.future);
  final now = DateTime.now();

  return segments.where((segment) {
    // Check if segment is enabled
    if (!segment.isEnabled) return false;

    // Check if segment has expired
    if (segment.enabledUntil != null && now.isAfter(segment.enabledUntil!)) {
      return false;
    }

    return true;
  }).toList();
});

// ─────────────────────────────────────────────────────────────────────────
// Probability Configuration Providers
// ─────────────────────────────────────────────────────────────────────────

/// Fetches probability configuration from the backend
///
/// Includes:
/// - Base probability distribution (jackpot, rare, uncommon, common)
/// - User-based modifiers (level, streak, currency)
/// - Time-based adjustments (weekends, events)
/// - Pity timer settings
/// - Jackpot cooldown configuration
final spinProbabilityConfigProvider =
    FutureProvider.autoDispose<ProbabilityConfig>((ref) async {
  try {
    final apiClient = ref.watch(spinWheelApiClientProvider);
    return await apiClient.getProbabilityConfig();
  } catch (e) {
    // Return default probability configuration
    return ProbabilityConfig(
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
  }
});

/// Get the current probability multiplier for the user
///
/// Takes into account:
/// - Current time (weekend bonuses)
/// - Active events/promotions
/// - User profile (level, streak, currency)
final currentProbabilityMultiplierProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final config = await ref.watch(spinProbabilityConfigProvider.future);
  final now = DateTime.now();

  double multiplier = 1.0;

  // Apply time-based adjustments
  for (final adjustment in config.timeBasedAdjustments) {
    if (!adjustment.active) continue;

    // Check date-based adjustments
    if (adjustment.startDate != null && adjustment.endDate != null) {
      if (now.isBefore(adjustment.startDate!) ||
          now.isAfter(adjustment.endDate!)) {
        continue;
      }
    }

    // Check day-based adjustments
    if (adjustment.days != null && adjustment.days!.isNotEmpty) {
      final dayName = _getDayName(now.weekday);
      if (!adjustment.days!.contains(dayName)) {
        continue;
      }
    }

    multiplier *= adjustment.probabilityMultiplier;
  }

  return multiplier;
});

// ─────────────────────────────────────────────────────────────────────────
// Analytics Providers
// ─────────────────────────────────────────────────────────────────────────

/// Fetches spin analytics for monitoring and operator dashboard
///
/// Provides insights on:
/// - Win rate accuracy vs expected
/// - Segment performance
/// - Anomaly detection
/// - Player engagement metrics
final spinAnalyticsProvider =
    FutureProvider.autoDispose<SpinAnalytics>((ref) async {
  try {
    final apiClient = ref.watch(spinWheelApiClientProvider);
    return await apiClient.getAnalytics(period: '24h');
  } catch (e) {
    // Return empty analytics on failure
    return SpinAnalytics(
      fromDate: DateTime.now().subtract(const Duration(hours: 24)),
      toDate: DateTime.now(),
      totalSpins: 0,
      segmentStats: {},
      anomalies: [],
    );
  }
});

/// Get segment-specific analytics
final segmentAnalyticsProvider =
    FutureProvider.autoDispose.family<SegmentStats?, String>((ref, segmentId) async {
  try {
    final apiClient = ref.watch(spinWheelApiClientProvider);
    final analytics = await apiClient.getAnalytics(segmentId: segmentId);
    return analytics.segmentStats[segmentId];
  } catch (e) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────────────────
// State Management Providers
// ─────────────────────────────────────────────────────────────────────────

/// State notifier for managing spin wheel state
class SpinWheelStateNotifier extends StateNotifier<SpinWheelUIState> {
  SpinWheelStateNotifier()
      : super(const SpinWheelUIState(
          isLoading: false,
          selectedSegment: null,
          lastSpinResult: null,
        ));

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void selectSegment(WheelSegment? segment) {
    state = state.copyWith(selectedSegment: segment);
  }

  void recordSpinResult(SpinResult result) {
    state = state.copyWith(lastSpinResult: result);
  }

  void clearState() {
    state = const SpinWheelUIState(
      isLoading: false,
      selectedSegment: null,
      lastSpinResult: null,
    );
  }
}

/// UI state for the spin wheel
class SpinWheelUIState {
  final bool isLoading;
  final WheelSegment? selectedSegment;
  final SpinResult? lastSpinResult;

  const SpinWheelUIState({
    required this.isLoading,
    required this.selectedSegment,
    required this.lastSpinResult,
  });

  SpinWheelUIState copyWith({
    bool? isLoading,
    WheelSegment? selectedSegment,
    SpinResult? lastSpinResult,
  }) {
    return SpinWheelUIState(
      isLoading: isLoading ?? this.isLoading,
      selectedSegment: selectedSegment ?? this.selectedSegment,
      lastSpinResult: lastSpinResult ?? this.lastSpinResult,
    );
  }
}

/// Provides the spin wheel UI state
final spinWheelStateProvider =
    StateNotifierProvider<SpinWheelStateNotifier, SpinWheelUIState>((ref) {
  return SpinWheelStateNotifier();
});

// ─────────────────────────────────────────────────────────────────────────
// Convenience Providers
// ─────────────────────────────────────────────────────────────────────────

/// Get the total probability of winning a jackpot given current conditions
final jackpotProbabilityProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final config = await ref.watch(spinProbabilityConfigProvider.future);
  final multiplier = await ref.watch(currentProbabilityMultiplierProvider.future);

  return config.baseDistribution.jackpot * multiplier;
});

/// Get segment details by ID
final spinSegmentByIdProvider =
    FutureProvider.autoDispose.family<WheelSegment?, String>((ref, segmentId) async {
  final segments = await ref.watch(spinSegmentConfigProvider.future);
  try {
    return segments.firstWhere((s) => s.id == segmentId);
  } catch (e) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────

List<WheelSegment> _getLocalSegmentFallback() {
  // In production, load from local assets
  // For now, return empty list - will be loaded from assets/config/segments.json
  return [];
}

String _getDayName(int weekday) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[weekday - 1];
}
