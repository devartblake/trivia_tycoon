import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/analytics/config_service.dart';

enum LogLevel { info, debug, warning, error, performance }

/// ANSI color codes for console output
class LogColors {
  static const String reset = '\x1B[0m';
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String gray = '\x1B[90m';

  // Bright colors
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  // Background colors
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';

  // Text styles
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;

  LogEntry(this.level, this.message, {this.source}) : timestamp = DateTime.now();

  @override
  String toString({bool useColors = true}) {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
    final sourceTag = source != null ? " [$source]" : "";

    if (!useColors || !kDebugMode) {
      // Plain text version for non-debug or when colors disabled
      final prefix = _getLogPrefix(level, useColors: false);
      return "$time $prefix$sourceTag: $message";
    }

    // Colored version for debug mode
    return _buildColoredLogString(time, sourceTag);
  }

  String _buildColoredLogString(String time, String sourceTag) {
    final coloredTime = "${LogColors.gray}$time${LogColors.reset}";
    final (coloredPrefix, levelColor) = _getColoredLogPrefix(level);
    final coloredSource = sourceTag.isNotEmpty
        ? " ${LogColors.dim}${LogColors.cyan}$sourceTag${LogColors.reset}"
        : "";
    final coloredMessage = "$levelColor$message${LogColors.reset}";

    return "$coloredTime $coloredPrefix$coloredSource: $coloredMessage";
  }

  static String _getLogPrefix(LogLevel level, {bool useColors = true}) {
    switch (level) {
      case LogLevel.info:
        return "[INFO] 📌";
      case LogLevel.debug:
        return "[DEBUG] 🐛";
      case LogLevel.warning:
        return "[WARN] ⚠️";
      case LogLevel.error:
        return "[ERROR] 🚨";
      case LogLevel.performance:
        return "[PERF] 🚀";
    }
  }

  static (String, String) _getColoredLogPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return (
        "${LogColors.brightBlue}${LogColors.bold}[INFO]${LogColors.reset} ${LogColors.blue}📌${LogColors.reset}",
        LogColors.brightBlue
        );
      case LogLevel.debug:
        return (
        "${LogColors.gray}${LogColors.bold}[DEBUG]${LogColors.reset} ${LogColors.gray}🐛${LogColors.reset}",
        LogColors.gray
        );
      case LogLevel.warning:
        return (
        "${LogColors.brightYellow}${LogColors.bold}[WARN]${LogColors.reset} ${LogColors.yellow}⚠️${LogColors.reset}",
        LogColors.brightYellow
        );
      case LogLevel.error:
        return (
        "${LogColors.brightRed}${LogColors.bold}[ERROR]${LogColors.reset} ${LogColors.red}🚨${LogColors.reset}",
        LogColors.brightRed
        );
      case LogLevel.performance:
        return (
        "${LogColors.brightMagenta}${LogColors.bold}[PERF]${LogColors.reset} ${LogColors.magenta}🚀${LogColors.reset}",
        LogColors.brightMagenta
        );
    }
  }
}

class LogManager {
  static final List<LogEntry> _logs = [];
  static bool _useColors = true;

  /// Stream of logs for real-time listening (UI debug tools)
  static final StreamController<LogEntry> _logStreamController =
  StreamController<LogEntry>.broadcast();

  static Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Enable or disable colored output
  static void setColorEnabled(bool enabled) {
    _useColors = enabled;
  }

  /// Check if colors are enabled
  static bool get colorsEnabled => _useColors;

  /// Main logging function
  static void log(
      String message, {
        LogLevel level = LogLevel.debug,
        String? source,
        bool forceLog = false,
      }) {
    final entry = LogEntry(level, message, source: source);

    if (kDebugMode || ConfigService.enableLogging || forceLog) {
      debugPrint(entry.toString(useColors: _useColors));
    }

    // Store log entry for later export or analysis
    _logs.add(entry);

    // Notify listeners (for UI debug panels, real-time log viewers)
    _logStreamController.add(entry);
  }

  /// Convenience methods for different log levels with enhanced formatting
  static void info(String message, {String? source}) {
    log(message, level: LogLevel.info, source: source);
  }

  static void debug(String message, {String? source}) {
    log(message, level: LogLevel.debug, source: source);
  }

  static void warning(String message, {String? source}) {
    log(message, level: LogLevel.warning, source: source);
  }

  static void error(String message, {String? source, Object? error, StackTrace? stackTrace}) {
    String fullMessage = message;
    if (error != null) {
      fullMessage += "\nError: $error";
    }
    if (stackTrace != null && kDebugMode) {
      fullMessage += "\nStack trace:\n$stackTrace";
    }
    log(fullMessage, level: LogLevel.error, source: source);
  }

  static void performance(String message, {String? source, Duration? duration}) {
    String fullMessage = message;
    if (duration != null) {
      fullMessage += " (${duration.inMilliseconds}ms)";
    }
    log(fullMessage, level: LogLevel.performance, source: source);
  }

  /// Log with custom colors (for special cases)
  static void logWithCustomColor(
      String message, {
        String? source,
        String color = LogColors.white,
        String backgroundColor = '',
        bool bold = false,
        bool underline = false,
      }) {
    if (!kDebugMode || !_useColors) {
      log(message, source: source);
      return;
    }

    final entry = LogEntry(LogLevel.info, message, source: source);
    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp);
    final sourceTag = source != null ? " [$source]" : "";

    String styles = color + backgroundColor;
    if (bold) styles += LogColors.bold;
    if (underline) styles += LogColors.underline;

    final coloredOutput = "${LogColors.gray}$time${LogColors.reset} "
        "${LogColors.brightCyan}[CUSTOM]${LogColors.reset}"
        "${LogColors.dim}${LogColors.cyan}$sourceTag${LogColors.reset}: "
        "$styles$message${LogColors.reset}";

    debugPrint(coloredOutput);

    _logs.add(entry);
    _logStreamController.add(entry);
  }

  /// Log method with highlighting for important information
  static void highlight(String message, {String? source}) {
    logWithCustomColor(
      message,
      source: source,
      color: LogColors.black,
      backgroundColor: LogColors.bgYellow,
      bold: true,
    );
  }

  /// Log method for success messages
  static void success(String message, {String? source}) {
    logWithCustomColor(
      message,
      source: source,
      color: LogColors.brightGreen,
      bold: true,
    );
  }

  /// Log method for critical messages
  static void critical(String message, {String? source}) {
    logWithCustomColor(
      message,
      source: source,
      color: LogColors.brightWhite,
      backgroundColor: LogColors.bgRed,
      bold: true,
    );
  }

  /// Performance timing helper
  static void timeOperation(String operationName, Function operation, {String? source}) {
    final stopwatch = Stopwatch()..start();
    performance("Starting: $operationName", source: source);

    try {
      operation();
    } finally {
      stopwatch.stop();
      performance("Completed: $operationName",
          source: source,
          duration: stopwatch.elapsed);
    }
  }

  /// Async performance timing helper
  static Future<T> timeAsyncOperation<T>(
      String operationName,
      Future<T> Function() operation,
      {String? source}
      ) async {
    final stopwatch = Stopwatch()..start();
    performance("Starting: $operationName", source: source);

    try {
      return await operation();
    } finally {
      stopwatch.stop();
      performance("Completed: $operationName",
          source: source,
          duration: stopwatch.elapsed);
    }
  }

  /// Create a divider in logs for better organization
  static void divider({String? label, String? source}) {
    const String dividerChar = "═";
    const int dividerLength = 80;

    if (label != null) {
      final padding = (dividerLength - label.length - 4) ~/ 2;
      final leftPadding = dividerChar * padding;
      final rightPadding = dividerChar * (dividerLength - padding - label.length - 4);
      logWithCustomColor(
        "$leftPadding $label $rightPadding",
        source: source,
        color: LogColors.brightCyan,
        bold: true,
      );
    } else {
      logWithCustomColor(
        dividerChar * dividerLength,
        source: source,
        color: LogColors.brightCyan,
      );
    }
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
  static String exportLogs({LogLevel? level, String? source, bool useColors = false}) {
    final logsToExport = getLogs(level: level, source: source);
    return logsToExport.map((entry) => entry.toString(useColors: useColors)).join('\n');
  }

  /// Export logs as JSON
  static String exportLogsAsJson({LogLevel? level, String? source}) {
    final logsToExport = getLogs(level: level, source: source);
    return logsToExport.map((entry) => {
      'timestamp': entry.timestamp.toIso8601String(),
      'level': entry.level.name,
      'message': entry.message,
      'source': entry.source,
    }).toList().toString();
  }

  /// Get log statistics
  static Map<String, dynamic> getLogStatistics() {
    final stats = <String, int>{};
    for (final level in LogLevel.values) {
      stats[level.name] = _logs.where((log) => log.level == level).length;
    }

    final sources = _logs
        .where((log) => log.source != null)
        .map((log) => log.source!)
        .toSet()
        .toList();

    return {
      'total_logs': _logs.length,
      'by_level': stats,
      'sources': sources,
      'colors_enabled': _useColors,
    };
  }

  /// Print log statistics with colors
  static void printStatistics() {
    divider(label: "LOG STATISTICS");
    final stats = getLogStatistics();

    success("Total logs: ${stats['total_logs']}");

    info("Logs by level:");
    final byLevel = stats['by_level'] as Map<String, int>;
    for (final entry in byLevel.entries) {
      final level = LogLevel.values.firstWhere((l) => l.name == entry.key);
      final count = entry.value;
      final (coloredPrefix, _) = LogEntry._getColoredLogPrefix(level);
      if (_useColors && kDebugMode) {
        debugPrint("  $coloredPrefix: $count");
      } else {
        info("  ${entry.key}: $count");
      }
    }

    final sources = stats['sources'] as List<String>;
    if (sources.isNotEmpty) {
      info("Active sources: ${sources.join(', ')}");
    }

    divider();
  }

  /// Clears all stored logs
  static void clearLogs() {
    _logs.clear();
    info("All logs cleared", source: "LogManager");
  }

  /// Dispose resources when they're no longer needed
  static void dispose() {
    _logStreamController.close();
  }
}