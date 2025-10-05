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

  Future<void> updateSyncStatus(String code, bool isSynced, {String? serverId}) async {
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
    history.add(event.toJson() as ReferralScanEvent);
    await _box?.put(_scanHistoryKey, history);
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
