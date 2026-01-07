import 'dart:async';
import 'package:trivia_tycoon/game/services/referral_invite_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'referral_invite_api_service.dart';
import '../models/referral_models.dart';

/// Service for managing referral invites
/// Follows the same pattern as ReferralService with offline-first approach
class ReferralInviteService {
  final ReferralInviteStorageService _storage;
  final ReferralInviteApiService _api;
  final String _userId;

  Timer? _expirationCheckTimer;

  ReferralInviteService({
    required ReferralInviteStorageService storage,
    required ReferralInviteApiService api,
    required String userId,
  })  : _storage = storage,
        _api = api,
        _userId = userId {
    // Start expiration checking
    _startExpirationTimer();
  }

  /// Create a new invite (offline-first)
  Future<ReferralInvite> createInvite({
    required String referralCode,
    String? inviteeName,
    String? inviteeEmail,
    int expirationDays = 7,
  }) async {
    // 1. Create invite locally first
    final now = DateTime.now().toUtc();
    final invite = ReferralInvite(
      id: const Uuid().v4(),
      referrerUserId: _userId,
      referralCode: referralCode,
      createdAt: now,
      expiresAt: now.add(Duration(days: expirationDays)),
      status: InviteStatus.pending,
      inviteeName: inviteeName,
      inviteeEmail: inviteeEmail,
      isSynced: false,
    );

    // 2. Save to local storage immediately
    await _storage.saveInvite(invite);

    // 3. Try to sync to server in background
    _syncInviteToServerBackground(invite);

    return invite;
  }

  /// Get all invites for the current user (local-first)
  List<ReferralInvite> getInvites() {
    // Try local storage first
    var invites = _storage.getUserInvites(_userId);

    // Check for expired invites and update them
    _checkAndUpdateExpiredInvites(invites);

    return invites;
  }

  /// Get pending invites
  List<ReferralInvite> getPendingInvites() {
    return getInvites().where((i) => i.isPending).toList();
  }

  /// Get redeemed invites
  List<ReferralInvite> getRedeemedInvites() {
    return getInvites().where((i) => i.isRedeemed).toList();
  }

  /// Get expired invites
  List<ReferralInvite> getExpiredInvites() {
    return getInvites().where((i) => i.isExpired).toList();
  }

  /// Get a specific invite by ID
  ReferralInvite? getInvite(String inviteId) {
    return _storage.getInvite(inviteId);
  }

  /// Redeem an invite
  Future<bool> redeemInvite({
    required String inviteId,
    required String redeemedByUserId,
    String? redeemerName,
  }) async {
    // 1. Get the invite from local storage
    final invite = _storage.getInvite(inviteId);
    if (invite == null) return false;

    // 2. Check if it's valid
    if (!invite.isPending) return false;

    // 3. Update locally first
    final metadata = Map<String, dynamic>.from(invite.metadata ?? {});
    if (redeemerName != null) {
      metadata['redeemerName'] = redeemerName;
    }

    final updatedInvite = invite.copyWith(
      status: InviteStatus.redeemed,
      redeemedBy: redeemedByUserId,
      redeemedAt: DateTime.now().toUtc(),
      metadata: metadata,
    );

    await _storage.saveInvite(updatedInvite);

    // 4. Try to sync to server
    try {
      await _api.redeemInvite(inviteId, redeemedByUserId);

      // Mark as synced
      final syncedInvite = updatedInvite.copyWith(isSynced: true);
      await _storage.saveInvite(syncedInvite);
    } catch (e) {
      // Server sync failed, but we have local update
      // Will sync later
    }

    return true;
  }

  /// Delete an invite
  Future<void> deleteInvite(String inviteId) async {
    // Try to delete from server first
    try {
      await _api.deleteInvite(inviteId);
    } catch (e) {
      // Server delete failed, continue with local
    }

    // Delete locally
    await _storage.deleteInvite(inviteId);
  }

  /// Get invite statistics
  Map<String, int> getStats() {
    final invites = getInvites();

    return {
      'total': invites.length,
      'pending': invites.where((i) => i.isPending).length,
      'redeemed': invites.where((i) => i.isRedeemed).length,
      'expired': invites.where((i) => i.isExpired).length,
    };
  }

  /// Sync all unsynced invites to server (call when network available)
  Future<void> syncUnsyncedInvites() async {
    final unsyncedInvites = _storage.getUnsyncedInvites();

    for (final invite in unsyncedInvites) {
      try {
        // Create on server
        final serverInvite = await _api.createInvite(invite);

        // Update local with server ID and sync status
        final syncedInvite = invite.copyWith(
          isSynced: true,
          serverId: serverInvite.serverId,
        );

        await _storage.saveInvite(syncedInvite);
      } catch (e) {
        // Failed to sync this one, will retry later
        continue;
      }
    }
  }

  /// Refresh invites from server (call periodically or on app start)
  Future<void> refreshFromServer() async {
    try {
      // Get invites from server
      final serverInvites = await _api.getInvites(_userId);

      // Merge with local invites
      for (final serverInvite in serverInvites) {
        final localInvite = _storage.getInvite(serverInvite.id);

        if (localInvite == null) {
          // New invite from server, save it
          await _storage.saveInvite(serverInvite);
        } else if (!localInvite.isSynced) {
          // Local invite not synced, keep local version
          continue;
        } else {
          // Update from server (server is source of truth for synced invites)
          await _storage.saveInvite(serverInvite);
        }
      }
    } catch (e) {
      // Server fetch failed, use local data
    }
  }

  /// Sync a single invite to server in background
  void _syncInviteToServerBackground(ReferralInvite invite) {
    Future(() async {
      try {
        final serverInvite = await _api.createInvite(invite);

        // Update sync status
        await _storage.updateSyncStatus(
          invite.id,
          true,
          serverId: serverInvite.serverId,
        );
      } catch (e) {
        // Sync failed, will retry later
      }
    });
  }

  /// Check and update expired invites
  void _checkAndUpdateExpiredInvites(List<ReferralInvite> invites) {
    final now = DateTime.now().toUtc();

    for (final invite in invites) {
      if (invite.status == InviteStatus.pending && now.isAfter(invite.expiresAt)) {
        // Mark as expired
        final expiredInvite = invite.copyWith(status: InviteStatus.expired);
        _storage.saveInvite(expiredInvite);

        // Try to update on server
        _updateStatusOnServerBackground(invite.id, InviteStatus.expired);
      }
    }
  }

  /// Update invite status on server in background
  void _updateStatusOnServerBackground(String inviteId, InviteStatus status) {
    Future(() async {
      try {
        await _api.updateInviteStatus(inviteId, status);
      } catch (e) {
        // Failed to update server, will retry later
      }
    });
  }

  /// Start timer to check for expired invites
  void _startExpirationTimer() {
    _expirationCheckTimer?.cancel();
    _expirationCheckTimer = Timer.periodic(
      const Duration(hours: 1),
          (_) {
        final invites = getInvites();
        _checkAndUpdateExpiredInvites(invites);
      },
    );
  }

  /// Dispose and cleanup
  void dispose() {
    _expirationCheckTimer?.cancel();
  }
}