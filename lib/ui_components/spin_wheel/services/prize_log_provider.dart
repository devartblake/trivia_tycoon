import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/settings/app_settings.dart';
import '../models/prize_entry.dart';

class PrizeLogNotifier extends AsyncNotifier<List<PrizeEntry>> {
  List<PrizeEntry> _allLogs = [];

  @override
  Future<List<PrizeEntry>> build() async {
    _allLogs = await AppSettings.getPrizeLog();
    return _allLogs;
  }

  Future<void> addEntry(PrizeEntry entry) async {
    _allLogs.add(entry);
    await AppSettings.setPrizeLog(_allLogs);
    state = AsyncData(_allLogs);
  }

  /// Filter logs by badge-related prize keywords (e.g. "diamond", "chest")
  void filterByBadge(String badge) {
    final filtered = _allLogs.where((e) {
      final name = e.prize.toLowerCase();
      return name.contains(badge.toLowerCase());
    }).toList();
    state = AsyncData(filtered);
  }

  void filterByDate(DateTime start, DateTime end) {
    final filtered = _allLogs.where((entry) {
      return entry.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
          entry.timestamp.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    state = AsyncData(filtered);
  }

  /// Reset filter to show full list
  void resetFilter() {
    state = AsyncData(_allLogs);
  }

  Future<String> exportToJson() async {
    final exportData = _allLogs.map((e) => e.toJson()).toList();
    return jsonEncode(exportData);
  }

  Future<String> exportToCsv() async {
    final buffer = StringBuffer();
    buffer.writeln("Prize,Timestamp");
    for (final entry in _allLogs) {
      buffer.writeln('"${entry.prize}","${entry.timestamp.toIso8601String()}"');
    }
    return buffer.toString();
  }

}

final prizeLogProvider = AsyncNotifierProvider<PrizeLogNotifier, List<PrizeEntry>>(PrizeLogNotifier.new);
