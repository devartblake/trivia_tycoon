import 'package:hive/hive.dart';

import '../models/referral_models.dart';

class ReferralInviteStorageService {
  static const String _boxName = 'referral_invites_box';
  static const String _invitesKey = 'user_invites';

  Box? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save an invite
  Future<void> saveInvite(ReferralInvite invite) async {
    final invites = getInvites();
    final index = invites.indexWhere((i) => i.id == invite.id);

    if (index != -1) {
      invites[index] = invite;
    } else {
      invites.add(invite);
    }

    await _box?.put(_invitesKey, invites.map((i) => i.toJson()).toList());
  }

  /// Get all invites
  List<ReferralInvite> getInvites() {
    final data = _box?.get(_invitesKey, defaultValue: <dynamic>[]);
    if (data == null) return [];

    try {
      return (data as List)
          .map((e) => ReferralInvite.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get invites for a specific user
  List<ReferralInvite> getUserInvites(String userId) {
    return getInvites()
        .where((invite) => invite.referrerUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a specific invite
  ReferralInvite? getInvite(String inviteId) {
    try {
      return getInvites().firstWhere((i) => i.id == inviteId);
    } catch (e) {
      return null;
    }
  }

  /// Update sync status
  Future<void> updateSyncStatus(
    String inviteId,
    bool isSynced, {
    String? serverId,
  }) async {
    final invite = getInvite(inviteId);
    if (invite != null) {
      final updated = invite.copyWith(
        isSynced: isSynced,
        serverId: serverId,
      );
      await saveInvite(updated);
    }
  }

  /// Update status
  Future<void> updateStatus(String inviteId, InviteStatus status) async {
    final invite = getInvite(inviteId);
    if (invite != null) {
      final updated = invite.copyWith(status: status);
      await saveInvite(updated);
    }
  }

  /// Delete invite
  Future<void> deleteInvite(String inviteId) async {
    final invites = getInvites();
    invites.removeWhere((i) => i.id == inviteId);
    await _box?.put(_invitesKey, invites.map((i) => i.toJson()).toList());
  }

  /// Get unsynced invites
  List<ReferralInvite> getUnsyncedInvites() {
    return getInvites().where((i) => !i.isSynced).toList();
  }

  /// Clear all invites
  Future<void> clearInvites() async {
    await _box?.delete(_invitesKey);
  }

  /// Close the box
  Future<void> close() async {
    await _box?.close();
  }
}