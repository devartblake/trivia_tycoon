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
          'userId': userId,
          'code': code,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'status': 'active',
        },
      );

      return ReferralCode.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create referral: $e');
    }
  }

  /// Get existing referral code from server
  Future<ReferralCode?> getReferral(String userId) async {
    try {
      final response = await _apiService.getRequest('referrals/$userId');
      return ReferralCode.fromJson(response);
    } catch (e) {
      // Return null if not found (404) or other errors
      return null;
    }
  }

  /// Track when someone scans a referral code
  Future<void> trackScanEvent(ReferralScanEvent event) async {
    try {
      await _apiService.post(
        '/referrals/track',
        body: event.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to track scan: $e');
    }
  }

  /// Get referral statistics for a user
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final response = await _apiService.getRequest('referrals/$userId/stats');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to get referral stats: $e');
    }
  }

  /// Validate a referral code
  Future<bool> validateCode(String code) async {
    try {
      final response = await _apiService.getRequest('referrals/validate/$code');
      return response['valid'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Apply a referral code (when someone signs up with a code)
  Future<void> applyReferralCode(String code, String newUserId) async {
    try {
      await _apiService.post(
        '/referrals/apply',
        body: {
          'code': code,
          'newUserId': newUserId,
          'appliedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to apply referral code: $e');
    }
  }
}
