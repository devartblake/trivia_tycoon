import '../../core/services/api_service.dart';
import '../models/referral_models.dart';

/// API service for referral invite operations
/// Follows the same pattern as ReferralApiService
class ReferralInviteApiService {
  final ApiService _apiService;

  ReferralInviteApiService(this._apiService);

  /// Create a new invite on the server
  Future<ReferralInvite> createInvite(ReferralInvite invite) async {
    try {
      final response = await _apiService.post(
        '/referrals/invites',
        body: invite.toJson(),
      );

      return ReferralInvite.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create invite: $e');
    }
  }

  /// Get all invites for a user
  Future<List<ReferralInvite>> getInvites(String userId) async {
    try {
      final response =
          await _apiService.getRequest('referrals/invites/user/$userId');
      return (response as List)
          .map((e) => ReferralInvite.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      // Return empty list if not found or error
      return [];
    }
  }

  /// Get a specific invite by ID
  Future<ReferralInvite?> getInvite(String inviteId) async {
    try {
      final response =
          await _apiService.getRequest('referrals/invites/$inviteId');
      return ReferralInvite.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Redeem an invite
  Future<void> redeemInvite(String inviteId, String redeemedByUserId) async {
    try {
      await _apiService.post(
        '/referrals/invites/$inviteId/redeem',
        body: {
          'redeemedBy': redeemedByUserId,
          'redeemedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to redeem invite: $e');
    }
  }

  /// Delete an invite
  Future<void> deleteInvite(String inviteId) async {
    try {
      await _apiService.delete('/referrals/invites/$inviteId');
    } catch (e) {
      throw Exception('Failed to delete invite: $e');
    }
  }

  /// Update invite status
  Future<void> updateInviteStatus(String inviteId, InviteStatus status) async {
    try {
      await _apiService.patch(
        '/referrals/invites/$inviteId',
        body: {
          'status': status.name,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update invite status: $e');
    }
  }

  /// Sync multiple invites to server
  Future<List<ReferralInvite>> syncInvites(List<ReferralInvite> invites) async {
    try {
      final response = await _apiService.post(
        '/referrals/invites/sync',
        body: {
          'invites': invites.map((i) => i.toJson()).toList(),
        },
      );

      return (response['invites'] as List)
          .map((e) => ReferralInvite.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception('Failed to sync invites: $e');
    }
  }

  /// Get invite statistics for a user
  Future<Map<String, int>> getInviteStats(String userId) async {
    try {
      final response =
          await _apiService.getRequest('referrals/invites/user/$userId/stats');
      return Map<String, int>.from(response);
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'redeemed': 0,
        'expired': 0,
      };
    }
  }
}
