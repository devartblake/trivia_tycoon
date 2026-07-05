import 'package:logging/logging.dart';
import '../api_service.dart';
import '../../networking/encrypted_api_client.dart';
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

class SpinStartResponse {
  final String spinId;
  final String? segmentId;
  final int? wheelStopIndex;
  final String claimToken;
  final DateTime expiresAtUtc;

  const SpinStartResponse({
    required this.spinId,
    this.segmentId,
    this.wheelStopIndex,
    required this.claimToken,
    required this.expiresAtUtc,
  });

  factory SpinStartResponse.fromJson(Map<String, dynamic> json) {
    return SpinStartResponse(
      spinId: json['spinId']?.toString() ?? '',
      segmentId: json['segmentId'] as String?,
      wheelStopIndex: (json['wheelStopIndex'] as num?)?.toInt(),
      claimToken: json['claimToken']?.toString() ?? '',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  }
}

/// Handles server-side spin wheel operations.
///
/// Endpoints:
///   GET  /arcade/spin/segments           — player-personalised segment list
///   POST /arcade/spin/claim              — grants reward and records history
///   POST /arcade/spin/start              — proposed; server-generated outcome
class SpinWheelApiService {
  static final _log = Logger('SpinWheelApiService');

  final ApiService _apiService;
  final EncryptedApiClient? _encryptedClient;

  SpinWheelApiService(this._apiService, {EncryptedApiClient? encryptedClient})
      : _encryptedClient = encryptedClient;

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

  /// DEPRECATED: Use [claimStartedReward] instead.
  /// Submits a completed spin to the server to grant the reward (old contract).
  ///
  /// Returns a [SpinClaimResponse] with the new coin balance.
  /// Throws [ApiRequestException] on server-side errors (e.g. cooldown not expired).
  ///
  /// This method uses the legacy contract and will be removed in a future version.
  /// All clients should migrate to [claimStartedReward] which uses the authoritative
  /// backend-generated contract.
  @Deprecated('Use claimStartedReward() instead. This method will be removed in v2.0.0')
  Future<SpinClaimResponse> claimReward({
    required String playerId,
    required String segmentId,
    required String spinId,
  }) async {
    _log.warning('DEPRECATED: claimReward() called. Migrate to claimStartedReward() with spinId + claimToken + idempotencyKey');
    final body = {
      'playerId': playerId,
      'segmentId': segmentId,
      'spinId': spinId,
    };
    final json = _encryptedClient != null
        ? await _encryptedClient!
            .postEncrypted('/arcade/spin/claim', body: body)
        : await _apiService.post('/arcade/spin/claim', body: body);
    return SpinClaimResponse.fromJson(json);
  }

  /// Claims a server-started spin using the backend-issued claim token.
  ///
  /// This is the backend-authoritative Spin & Earn contract that should replace
  /// [claimReward] once `POST /arcade/spin/start` is live in every environment.
  Future<SpinClaimResponse> claimStartedReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) async {
    _log.info('Claiming server-started spin reward: spinId=$spinId');
    final body = {
      'spinId': spinId,
      'claimToken': claimToken,
      'idempotencyKey': idempotencyKey,
    };
    final json = _encryptedClient != null
        ? await _encryptedClient!
            .postEncrypted('/arcade/spin/claim', body: body)
        : await _apiService.post('/arcade/spin/claim', body: body);
    return SpinClaimResponse.fromJson(json);
  }

  /// Requests a server-generated spin outcome.
  /// Falls back to a mock response while POST /arcade/spin/start is proposed/future.
  Future<SpinStartResponse> startSpin({String? playerId}) async {
    _log.info('Requesting server-generated spin start');
    try {
      final body = <String, dynamic>{
        if (playerId != null) 'playerId': playerId,
      };
      final json = await _apiService.post('/arcade/spin/start', body: body);
      return SpinStartResponse.fromJson(json);
    } catch (e) {
      _log.warning('startSpin backend unavailable, using mock: $e');
      return _mockStartResponse();
    }
  }

  static SpinStartResponse _mockStartResponse() {
    return SpinStartResponse(
      spinId: 'mock-spin-${DateTime.now().millisecondsSinceEpoch}',
      segmentId: null,
      wheelStopIndex: null,
      claimToken: 'mock-claim-token',
      expiresAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
  }

  /// Generates a unique idempotency key for spin claim operations.
  /// Used to ensure idempotent claim requests (e.g., if request is retried).
  static String generateIdempotencyKey() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }
}

/// Migration Helper: Wrapper to facilitate gradual migration from old to new contract.
///
/// Usage:
/// ```dart
/// // Old way (deprecated):
/// final response = await spinService.claimReward(
///   playerId: playerId,
///   segmentId: segment.id,
///   spinId: spinId,
/// );
///
/// // New way (recommended):
/// // Step 1: Start a spin with the backend
/// final spinStart = await spinService.startSpin(playerId: playerId);
///
/// // Step 2: Use the backend-issued claimToken
/// final response = await spinService.claimStartedReward(
///   spinId: spinStart.spinId,
///   claimToken: spinStart.claimToken,
///   idempotencyKey: SpinWheelApiService.generateIdempotencyKey(),
/// );
/// ```
extension SpinWheelMigration on SpinWheelApiService {
  /// Convenience method to claim a spin after calling startSpin().
  /// This is the recommended approach for new implementations.
  ///
  /// Example:
  /// ```dart
  /// final spinStart = await service.startSpin(playerId: userId);
  /// final claim = await service.claimStartedSpin(spinStart);
  /// ```
  Future<SpinClaimResponse> claimStartedSpin(SpinStartResponse spinStart) {
    return claimStartedReward(
      spinId: spinStart.spinId,
      claimToken: spinStart.claimToken,
      idempotencyKey: SpinWheelApiService.generateIdempotencyKey(),
    );
  }
}
