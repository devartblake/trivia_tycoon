import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../../core/services/settings/qr_settings_service.dart';
import '../models/qr_scan_type.dart';
import '../models/scan_history_item.dart';

class QrHistoryService {
  static const String _key = 'qr_scan_history';

  static String get storageKey => _key;
  final AppCacheService cache;
  final QrSettingsService settings;
  static QrHistoryService? _instance;
  DateTime? _lastAutoSync;

  /// Singleton accessor
  static QrHistoryService get instance {
    _instance ??= QrHistoryService(
        cache: AppCacheService(),
        settings: QrSettingsService()
    );
    return _instance!;
  }

  QrHistoryService({required this.cache, required this.settings});

  /// Retrieve scan history as structured entries
  Future<List<ScanHistoryItem>> getHistory() async {
    return await cache.loadScanHistory();
  }

  /// Save a new scan with type + timestamp
  Future<void> saveScan(String value) async {
    final type = detectQrType(value).name;
    final history = await getHistory();

    // Avoid duplicates
    if (!history.any((h) => h.value == value)) {
      final newItem = ScanHistoryItem(
        value: value,
        timestamp: DateTime.now(),
        type: type,
      );

      final scanLimit = await settings.getQrScanHistoryLimit();
      final updated = [newItem, ...history].take(scanLimit).toList();

      await cache.saveScanHistory(updated);
    }
  }

  Future<void> clearHistory() async => await cache.clearScanHistory();

  Future<void> syncToBackend(
      {required String userId, int? retentionDays}) async {
    final allScans = await QrHistoryService.instance.getHistory();

    final filteredScans = retentionDays != null
        ? allScans.where((scan) =>
    DateTime
        .now()
        .difference(scan.timestamp)
        .inDays <= retentionDays).toList()
        : allScans;

    final payload = {
      'user_id': userId,
      'scans': filteredScans.map((e) => e.toJson()).toList(),
    };

    final uri = Uri.parse(
        'https://your.api.url/api/scans/upload${retentionDays != null
            ? '?days=$retentionDays'
            : ''}');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync scan history: ${response.body}');
    }
  }

  Future<void> autoSyncIfDue({
    required String userId,
    int retentionDays = 7,
    Duration interval = const Duration(hours: 6),
  }) async {
    final now = DateTime.now();

    // Skip if synced recently
    if (_lastAutoSync != null && now.difference(_lastAutoSync!) < interval) return;

    try {
      await syncToBackend(userId: userId, retentionDays: retentionDays);
      _lastAutoSync = now;
    } catch (e) {
      // Optional: log to file or analytics
    }
  }
}