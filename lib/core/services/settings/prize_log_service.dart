import 'package:hive/hive.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/models/prize_entry.dart';

/// PrizeLogService manages the storage and retrieval of prize log entries
/// and filter preferences for exporting or viewing prize data.
class PrizeLogService {
  static const String _boxName = 'settings';

  /// Stores the entire prize log as a list of serialized JSON maps.
  Future<void> setPrizeLog(List<PrizeEntry> entries) async {
    final box = await Hive.openBox(_boxName);
    final data = entries.map((e) => e.toJson()).toList();
    await box.put('prizeLog', data);
  }

  /// Retrieves the list of prize log entries from local storage.
  /// Returns an empty list if no entries are found.
  Future<List<PrizeEntry>> getPrizeLog() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('prizeLog', defaultValue: []);
    if (raw is List) {
      return raw
          .map((e) => PrizeEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Saves filter settings for prize log viewing or exporting.
  ///
  /// - [exportFormat] — file format (e.g., 'json', 'csv')
  /// - [badge] — badge filter
  /// - [viewRange] — range of entries to show (e.g., 'all', 'week', etc.)
  Future<void> savePrizeLogFilters({
    String? exportFormat,
    String? badge,
    String? viewRange,
  }) async {
    final box = await Hive.openBox(_boxName);
    if (exportFormat != null) {
      await box.put('prize_export_format', exportFormat);
    }
    if (badge != null) {
      await box.put('prize_filter_badge', badge);
    }
    if (viewRange != null) {
      await box.put('prize_filter_view_range', viewRange);
    }
  }

  /// Returns the saved export format or defaults to 'json'.
  Future<String> getExportFormat() async {
    final box = await Hive.openBox(_boxName);
    return box.get('prize_export_format', defaultValue: 'json');
  }

  /// Returns the selected badge filter or an empty string.
  Future<String> getFilterBadge() async {
    final box = await Hive.openBox(_boxName);
    return box.get('prize_filter_badge', defaultValue: '');
  }

  /// Returns the selected view range filter or defaults to 'all'.
  Future<String> getFilterViewRange() async {
    final box = await Hive.openBox(_boxName);
    return box.get('prize_filter_view_range', defaultValue: 'all');
  }
}
