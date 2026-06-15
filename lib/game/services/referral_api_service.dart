import 'package:uuid/uuid.dart';

import '../../core/services/api_service.dart';
import '../models/referral_models.dart';

// API service for referral invite operations
class ReferralApiService {
  final ApiService _apiService;

  ReferralApiService(this._apiService);

  /// Create a new referral code on the server
  Future<ReferralCode> createReferral(String userId, String code) async {
    try {
      final response = await _apiService.post(
        '/referrals',
        body: {
          'ownerPlayerId': userId,
        },
      );

      return ReferralCode.fromJson({
        ...response,
        'ownerUserId': response['ownerPlayerId'] ?? userId,
        'createdAt': response['createdAtUtc'] ?? response['createdAt'],
        'isSynced': true,
      });
    } catch (e) {
      throw Exception('Failed to create referral: $e');
    }
  }

  /// Get existing referral code from server by referral code.
  Future<ReferralCode?> getReferral(String code) async {
    try {
      final response = await _apiService.get('/referrals/$code');
      return ReferralCode.fromJson(response);
    } catch (e) {
      // Return null if not found (404) or other errors
      return null;
    }
  }

  /// Track when someone scans a referral code
  Future<void> trackScanEvent(ReferralScanEvent event) async {
    try {
      final scannerUserId = event.scannerUserId;
      if (scannerUserId == null || scannerUserId.trim().isEmpty) {
        return;
      }

      await _apiService.post(
        '/qr/track-scan',
        body: {
          'eventId': const Uuid().v4(),
          'playerId': scannerUserId,
          'value': event.code,
          'occurredAtUtc': event.scannedAt.toUtc().toIso8601String(),
          'type': 2,
        },
      );
    } catch (e) {
      throw Exception('Failed to track scan: $e');
    }
  }

  /// Get referral statistics for a user
  Future<Map<String, dynamic>> getReferralStats(String _) async {
    return {
      'totalReferrals': 0,
      'successfulReferrals': 0,
      'pendingReferrals': 0,
      'rewards': 0,
    };
  }

  /// Validate a referral code
  Future<bool> validateCode(String code) async {
    try {
      final response = await _apiService.get('/referrals/$code');
      return (response['code'] ?? '').toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Apply a referral code (when someone signs up with a code)
  Future<void> applyReferralCode(String code, String newUserId) async {
    try {
      await _apiService.post(
        '/referrals/$code/redeem',
        body: {
          'eventId': const Uuid().v4(),
          'redeemerPlayerId': newUserId,
        },
      );
    } catch (e) {
      throw Exception('Failed to apply referral code: $e');
    }
  }
}
