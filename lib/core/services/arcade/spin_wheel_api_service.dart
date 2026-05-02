import 'package:logging/logging.dart';
import '../api_service.dart';
import '../../../ui_components/spin_wheel/models/spin_system_models.dart';

class SpinClaimResponse {
  final bool success;
  final int coinsGranted;
  final int newBalance;
  final String? message;

  const SpinClaimResponse({
    required this.success,
    required this.coinsGranted,
    required this.newBalance,
    this.message,
  });

  factory SpinClaimResponse.fromJson(Map<String, dynamic> json) {
    return SpinClaimResponse(
      success: (json['success'] as bool?) ?? false,
      coinsGranted: (json['coinsGranted'] as num?)?.toInt() ?? 0,
      newBalance: (json['newBalance'] as num?)?.toInt() ?? 0,
      message: json['message'] as String?,
    );
  }
}

/// Handles server-side spin wheel operations.
///
/// Endpoints (backend team to implement):
///   GET  /arcade/spin/segments           — player-personalised segment list
///   POST /arcade/spin/claim              — grants reward and records history
class SpinWheelApiService {
  static final _log = Logger('SpinWheelApiService');

  final ApiService _apiService;

  SpinWheelApiService(this._apiService);

  /// Fetches wheel segments from the server.
  /// Falls back to an empty list on failure (caller should use local fallback).
  Future<List<WheelSegment>> fetchSegments({String? playerId}) async {
    final Map<String, dynamic>? params =
        playerId != null ? {'playerId': playerId} : null;
    final items = await _apiService.getList(
      '/arcade/spin/segments',
      queryParameters: params,
    );
    return items
        .map((e) => WheelSegment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Submits a completed spin to the server to grant the reward.
  ///
  /// Returns a [SpinClaimResponse] with the new coin balance.
  /// Throws [ApiRequestException] on server-side errors (e.g. cooldown not expired).
  Future<SpinClaimResponse> claimReward({
    required String playerId,
    required String segmentId,
    required String spinId,
  }) async {
    _log.info('Claiming spin reward: segmentId=$segmentId spinId=$spinId');
    final json = await _apiService.post(
      '/arcade/spin/claim',
      body: {
        'playerId': playerId,
        'segmentId': segmentId,
        'spinId': spinId,
      },
    );
    return SpinClaimResponse.fromJson(json);
  }
}
