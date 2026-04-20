import 'package:hive/hive.dart';
import '../models/referral_models.dart';

class ReferralStorageService {
  static const String _boxName = 'referral_box';
  static const String _codeKey = 'user_referral_code';
  static const String _scanHistoryKey = 'scan_history';

  Box? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveReferralCode(ReferralCode referral) async {
    await _box?.put(_codeKey, referral.toJson());
  }

  ReferralCode? getReferralCode() {
    final data = _box?.get(_codeKey);
    if (data == null) return null;
    try {
      return ReferralCode.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  Future<void> updateSyncStatus(String code, bool isSynced,
      {String? serverId}) async {
    final current = getReferralCode();
    if (current != null && current.code == code) {
      final updated = current.copyWith(
        isSynced: isSynced,
        serverId: serverId,
      );
      await saveReferralCode(updated);
    }
  }

  Future<void> saveScanEvent(ReferralScanEvent event) async {
    final history = getScanHistory();
    history.add(event);
    await _box?.put(_scanHistoryKey, history.map((e) => e.toJson()).toList());
  }

  List<ReferralScanEvent> getScanHistory() {
    final data = _box?.get(_scanHistoryKey, defaultValue: <dynamic>[]);
    if (data == null) return [];
    try {
      return (data as List)
          .map((e) => ReferralScanEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearReferralCode() async {
    await _box?.delete(_codeKey);
  }

  Future<void> clearScanHistory() async {
    await _box?.delete(_scanHistoryKey);
  }

  Future<void> close() async {
    await _box?.close();
  }
}

/// This maintains backward compatibility while adding invite functionality
extension ReferralInviteStorage on ReferralStorageService {
  static const String _invitesKey = 'user_invites';

  /// Save an invite to storage
  Future<void> saveInvite(ReferralInvite invite) async {
    final invites = getInvites();
    final index = invites.indexWhere((i) => i.id == invite.id);

    if (index != -1) {
      invites[index] = invite;
    } else {
      invites.add(invite);
    }

    await _saveInviteList(invites);
  }

  /// Get all invites from storage
  List<ReferralInvite> getInvites() {
    // Access the private _box field through the instance
    final box = _getBox();
    final data = box?.get(_invitesKey, defaultValue: <dynamic>[]);
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

  /// Get a specific invite by ID
  ReferralInvite? getInvite(String inviteId) {
    try {
      return getInvites().firstWhere((i) => i.id == inviteId);
    } catch (e) {
      return null;
    }
  }

  /// Update invite sync status
  Future<void> updateInviteSyncStatus(
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

  /// Update invite status
  Future<void> updateInviteStatus(String inviteId, InviteStatus status) async {
    final invite = getInvite(inviteId);
    if (invite != null) {
      final updated = invite.copyWith(status: status);
      await saveInvite(updated);
    }
  }

  /// Delete an invite
  Future<void> deleteInvite(String inviteId) async {
    final invites = getInvites();
    invites.removeWhere((i) => i.id == inviteId);
    await _saveInviteList(invites);
  }

  /// Get unsynced invites
  List<ReferralInvite> getUnsyncedInvites() {
    return getInvites().where((i) => !i.isSynced).toList();
  }

  /// Clear all invites
  Future<void> clearInvites() async {
    final box = _getBox();
    await box?.delete(_invitesKey);
  }

  /// Private helper to save invite list
  Future<void> _saveInviteList(List<ReferralInvite> invites) async {
    final box = _getBox();
    await box?.put(
      _invitesKey,
      invites.map((i) => i.toJson()).toList(),
    );
  }

  /// Private helper to access the box
  /// Note: Add a getter in ReferralStorageService: Box? get box => _box;
  Box? _getBox() {
    // This assumes you add: Box? get box => _box; to ReferralStorageService
    return _box;
  }
}
