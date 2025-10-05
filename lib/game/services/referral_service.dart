import 'package:trivia_tycoon/game/services/referral_api_service.dart';
import 'package:trivia_tycoon/game/services/referral_storage_service.dart';
import '../models/referral_models.dart';
import '../utils/qr_payload.dart';
import '../utils/referral_code_gen.dart';

class ReferralService {
  final ReferralStorageService _storage;
  final ReferralApiService _api;
  final String _userId;
  final String _baseUrl;

  ReferralService({
    required ReferralStorageService storage,
    required ReferralApiService api,
    required String userId,
    String baseUrl = 'https://www.trivia.app',
  })  : _storage = storage,
        _api = api,
        _userId = userId,
        _baseUrl = baseUrl;

  /// Get or create a referral code for the current user
  Future<ReferralCode> getOrCreateReferralCode() async {
    // 1. Try local storage first (offline-first)
    var referral = _storage.getReferralCode();

    if (referral != null && referral.ownerUserId == _userId) {
      // If we have a local code but it's not synced, try to sync it
      if (!referral.isSynced) {
        _syncToServerBackground(referral);
      }
      return referral;
    }

    // 2. Try to fetch from server
    try {
      referral = await _api.getReferral(_userId);
      if (referral != null) {
        // Save to local storage
        await _storage.saveReferralCode(referral);
        return referral;
      }
    } catch (e) {
      // Server fetch failed, continue to create new
    }

    // 3. Create new referral code
    final newCode = ReferralCodeGen.generate();
    referral = ReferralCode(
      code: newCode,
      ownerUserId: _userId,
      createdAt: DateTime.now().toUtc(),
      status: ReferralCodeStatus.active,
      isSynced: false,
    );

    // Save locally first
    await _storage.saveReferralCode(referral);

    // Try to sync to server
    try {
      final serverReferral = await _api.createReferral(_userId, newCode);
      final syncedReferral = referral.copyWith(
        isSynced: true,
        serverId: serverReferral.serverId,
      );
      await _storage.saveReferralCode(syncedReferral);
      return syncedReferral;
    } catch (e) {
      // Server sync failed, but we have local copy
      return referral;
    }
  }

  /// Get the shareable referral link
  String getReferralLink(String code) {
    return '$_baseUrl/register?inviteCode=$code';
  }

  /// Get the QR code data with full payload
  String getQRCodeData(ReferralCode referral) {
    return QrPayload.buildUri(
      code: referral.code,
      ownerUserId: referral.ownerUserId,
      issuedAtUnix: referral.createdAt.millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Track a scan event
  Future<void> trackScan(String code, {String? scannerId, String source = 'qr'}) async {
    final event = ReferralScanEvent(
      code: code,
      scannerUserId: scannerId,
      scannedAt: DateTime.now().toUtc(),
      source: source,
    );

    // Save locally
    await _storage.saveScanEvent(event);

    // Try to send to server
    try {
      await _api.trackScanEvent(event);
    } catch (e) {
      // Failed to send to server, will retry later
    }
  }

  /// Apply a referral code (when user signs up with someone's code)
  Future<bool> applyReferralCode(String code) async {
    try {
      // Validate code first
      final isValid = await _api.validateCode(code);
      if (!isValid) return false;

      // Apply the code
      await _api.applyReferralCode(code, _userId);

      // Track the scan
      await trackScan(code, scannerId: _userId, source: 'manual');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get referral statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await _api.getReferralStats(_userId);
    } catch (e) {
      return {
        'totalReferrals': 0,
        'successfulReferrals': 0,
        'pendingReferrals': 0,
        'rewards': 0,
      };
    }
  }

  /// Sync local referral code to server in background
  void _syncToServerBackground(ReferralCode referral) {
    Future(() async {
      try {
        await _api.createReferral(_userId, referral.code);
        await _storage.updateSyncStatus(referral.code, true);
      } catch (e) {
        // Sync failed, will retry next time
      }
    });
  }

  /// Sync all pending scan events to server
  Future<void> syncPendingScanEvents() async {
    // This could be called periodically or when network becomes available
    final history = _storage.getScanHistory();
    for (final event in history) {
      try {
        await _api.trackScanEvent(event);
      } catch (e) {
        // Failed, will retry later
      }
    }
  }
}