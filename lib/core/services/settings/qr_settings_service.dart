import 'package:hive/hive.dart';

/// Handles persistent settings related to QR scan behavior.
class QrSettingsService {
  static const String _boxName = 'settings';
  static const String _scanLimitKey = 'qr_scan_limit';
  static const int _defaultLimit = 50;

  /// Save the maximum number of scan history items to retain
  Future<void> setScanHistoryLimit(int limit) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_scanLimitKey, limit);
  }

  /// Retrieve the stored scan history limit or fallback to default
  Future<int> getQrScanHistoryLimit() async {
    final box = await Hive.openBox(_boxName);
    final limit = box.get(_scanLimitKey);
    if (limit is int && limit > 0) return limit;
    return _defaultLimit;
  }
}
