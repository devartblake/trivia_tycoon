import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/analytics/config_service.dart';

enum LogLevel { info, debug, warning, error, performance }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;

  LogEntry(this.level, this.message, {this.source}) : timestamp = DateTime.now();

  @override
  String toString() {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
    final sourceTag = source != null ? " [$source]" : "";
    final prefix = _getLogPrefix(level);
    return "$time $prefix$sourceTag: $message";
  }

  static String _getLogPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return "[INFO] 📌";
      case LogLevel.debug:
        return "[DEBUG] 🐞";
      case LogLevel.warning:
        return "[WARN] ⚠️";
      case LogLevel.error:
        return "[ERROR] 🚨";
      case LogLevel.performance:
        return "[PERF] 🚀";
    }
  }
}

class LogManager {
  static final List<LogEntry> _logs = [];

  /// Stream of logs for real-time listening (UI debug tools)
  static final StreamController<LogEntry> _logStreamController =
  StreamController<LogEntry>.broadcast();

  static Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Main logging function
  static void log(
      String message, {
        LogLevel level = LogLevel.debug,
        String? source,
        bool forceLog = false,
      }) {
    final entry = LogEntry(level, message, source: source);

    if (kDebugMode || ConfigService.enableLogging || forceLog) {
      debugPrint(entry.toString());
    }

    // Store log entry for later export or analysis
    _logs.add(entry);

    // Notify listeners (for UI debug panels, real-time log viewers)
    _logStreamController.add(entry);
  }

  /// Retrieve logs by level
  static List<LogEntry> getLogs({LogLevel? level, String? source}) {
    return _logs.where((entry) {
      final levelMatch = level == null || entry.level == level;
      final sourceMatch = source == null || entry.source == source;
      return levelMatch && sourceMatch;
    }).toList();
  }

  /// Export logs as a formatted string
  static String exportLogs({LogLevel? level, String? source}) {
    final logsToExport = getLogs(level: level, source: source);
    return logsToExport.map((entry) => entry.toString()).join('\n');
  }

  /// Clears all stored logs
  static void clearLogs() => _logs.clear();

  /// Dispose resources when they're no longer needed
  static void dispose() => _logStreamController.close();
}
