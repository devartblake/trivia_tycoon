import 'dart:io';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class ColorLogManager {
  static final Queue<ColorLogEntry> _logEntries = Queue<ColorLogEntry>();
  static const int _maxLogEntries = 1000; // Prevent memory overflow
  static const int _maxExportEntries = 5000; // Limit export size

  // Performance tracking
  static int _totalSelections = 0;
  static final Map<String, int> _colorFrequency = {};
  static DateTime? _sessionStart;

  /// Log color selection with structured data
  static void logColorSelection(String hexColor, {
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    try {
      // Validate hex color format
      if (!_isValidHexColor(hexColor)) {
        LogManager.log(
          "Invalid HEX color format: $hexColor",
          level: LogLevel.warning,
          source: "ColorLogManager",
        );
        return;
      }

      _sessionStart ??= DateTime.now();
      _totalSelections++;

      // Track color frequency
      _colorFrequency[hexColor] = (_colorFrequency[hexColor] ?? 0) + 1;

      final entry = ColorLogEntry(
        timestamp: DateTime.now(),
        hexColor: hexColor,
        source: source ?? 'unknown',
        metadata: metadata ?? {},
        sessionId: _getSessionId(),
      );

      _logEntries.add(entry);

      // Maintain size limit
      while (_logEntries.length > _maxLogEntries) {
        _logEntries.removeFirst();
      }

      // Log to main log manager with structured info
      LogManager.log(
        "Color selected: $hexColor from $source (frequency: ${_colorFrequency[hexColor]})",
        level: LogLevel.info,
        source: "ColorPicker",
      );

    } catch (e) {
      LogManager.log(
        "Error logging color selection: $e",
        level: LogLevel.error,
        source: "ColorLogManager",
      );
    }
  }

  /// Log color picker events
  static void logEvent(ColorLogEventType type, {
    String? color,
    String? description,
    Map<String, dynamic>? data,
  }) {
    try {
      final entry = ColorLogEntry(
        timestamp: DateTime.now(),
        eventType: type,
        hexColor: color,
        description: description,
        metadata: data ?? {},
        sessionId: _getSessionId(),
      );

      _logEntries.add(entry);

      // Maintain size limit
      while (_logEntries.length > _maxLogEntries) {
        _logEntries.removeFirst();
      }

    } catch (e) {
      debugPrint('Error logging color picker event: $e');
    }
  }

  /// Validate hex color format
  static bool _isValidHexColor(String hex) {
    if (hex.isEmpty) return false;

    // Remove # if present
    final cleanHex = hex.replaceAll('#', '');

    // Check if valid hex format (3, 4, 6, or 8 characters)
    if (![3, 4, 6, 8].contains(cleanHex.length)) return false;

    // Check if all characters are valid hex digits
    return RegExp(r'^[0-9A-Fa-f]+$').hasMatch(cleanHex);
  }

  /// Get current session ID
  static String _getSessionId() {
    return _sessionStart?.millisecondsSinceEpoch.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Get session duration in seconds
  static int _getSessionDuration() {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  /// Export logs with filtering and formatting options
  static Future<String> exportLogs({
    ColorLogFormat format = ColorLogFormat.json,
    DateTime? startDate,
    DateTime? endDate,
    List<ColorLogEventType>? eventTypes,
    bool includeMetadata = true,
  }) async {
    try {
      // Filter logs based on criteria
      final filteredLogs = _logEntries.where((entry) {
        if (startDate != null && entry.timestamp.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && entry.timestamp.isAfter(endDate)) {
          return false;
        }
        if (eventTypes != null && entry.eventType != null &&
            !eventTypes.contains(entry.eventType)) {
          return false;
        }
        return true;
      }).take(_maxExportEntries).toList();

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final extension = format == ColorLogFormat.json ? 'json' : 'txt';
      final filename = 'color_picker_logs_$timestamp.$extension';

      // Get export directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      // Format and write logs
      String content;
      switch (format) {
        case ColorLogFormat.json:
          content = _formatAsJson(filteredLogs, includeMetadata);
          break;
        case ColorLogFormat.csv:
          content = _formatAsCsv(filteredLogs, includeMetadata);
          break;
        case ColorLogFormat.text:
        default:
          content = _formatAsText(filteredLogs, includeMetadata);
          break;
      }

      await file.writeAsString(content);

      // Log export event
      logEvent(
        ColorLogEventType.exportLogs,
        description: 'Exported ${filteredLogs.length} log entries',
        data: {
          'format': format.name,
          'filename': filename,
          'entryCount': filteredLogs.length,
        },
      );

      return file.path;
    } catch (e) {
      final errorMsg = "Error exporting logs: $e";
      LogManager.log(
        errorMsg,
        level: LogLevel.error,
        source: "ColorLogManager",
      );
      return errorMsg;
    }
  }

  /// Format logs as JSON
  static String _formatAsJson(List<ColorLogEntry> logs, bool includeMetadata) {
    final data = {
      'exportInfo': {
        'timestamp': DateTime.now().toIso8601String(),
        'totalEntries': logs.length,
        'sessionStats': getSessionStats(),
      },
      'logs': logs.map((entry) => entry.toJson(includeMetadata)).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Format logs as CSV
  static String _formatAsCsv(List<ColorLogEntry> logs, bool includeMetadata) {
    final buffer = StringBuffer();

    // CSV Header
    if (includeMetadata) {
      buffer.writeln('Timestamp,Event Type,Color,Source,Description,Metadata');
    } else {
      buffer.writeln('Timestamp,Event Type,Color,Source,Description');
    }

    // CSV Data
    for (final entry in logs) {
      final row = [
        entry.timestamp.toIso8601String(),
        entry.eventType?.name ?? 'color_selection',
        entry.hexColor ?? '',
        entry.source ?? '',
        entry.description ?? '',
        if (includeMetadata) jsonEncode(entry.metadata),
      ];

      // Escape commas and quotes
      final escapedRow = row.map((field) =>
      '"${field.toString().replaceAll('"', '""')}"'
      ).join(',');

      buffer.writeln(escapedRow);
    }

    return buffer.toString();
  }

  /// Format logs as human-readable text
  static String _formatAsText(List<ColorLogEntry> logs, bool includeMetadata) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Color Picker Log Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Entries: ${logs.length}');
    buffer.writeln('Session Stats: ${getSessionStats()}');
    buffer.writeln('${'=' * 50}\n');

    // Log entries
    for (final entry in logs) {
      buffer.writeln('[${entry.timestamp}] ${entry.eventType?.name.toUpperCase() ?? 'COLOR_SELECTION'}');
      if (entry.hexColor != null) {
        buffer.writeln('  Color: ${entry.hexColor}');
      }
      if (entry.source != null) {
        buffer.writeln('  Source: ${entry.source}');
      }
      if (entry.description != null) {
        buffer.writeln('  Description: ${entry.description}');
      }
      if (includeMetadata && entry.metadata.isNotEmpty) {
        buffer.writeln('  Metadata: ${entry.metadata}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get session statistics
  static Map<String, dynamic> getSessionStats() {
    return {
      'totalSelections': _totalSelections,
      'uniqueColors': _colorFrequency.length,
      'sessionDuration': _getSessionDuration(),
      'sessionStart': _sessionStart?.toIso8601String(),
      'mostUsedColors': _getMostUsedColors(5),
      'averageSelectionsPerMinute': _getAverageSelectionsPerMinute(),
    };
  }

  /// Get most frequently used colors
  static List<Map<String, dynamic>> _getMostUsedColors(int count) {
    final sorted = _colorFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((entry) => {
      'color': entry.key,
      'count': entry.value,
      'percentage': (_totalSelections > 0 ? (entry.value / _totalSelections * 100) : 0).toStringAsFixed(1),
    }).toList();
  }

  /// Calculate average selections per minute
  static double _getAverageSelectionsPerMinute() {
    final duration = _getSessionDuration();
    if (duration == 0) return 0.0;
    return _totalSelections / (duration / 60.0);
  }

  /// Clear all logs
  static void clearLogs() {
    _logEntries.clear();
    _colorFrequency.clear();
    _totalSelections = 0;
    _sessionStart = null;

    logEvent(
      ColorLogEventType.clearLogs,
      description: 'All logs cleared',
    );
  }

  /// Get current log count
  static int getLogCount() => _logEntries.length;

  /// Get logs for a specific time range
  static List<ColorLogEntry> getLogsInRange(DateTime start, DateTime end) {
    return _logEntries.where((entry) =>
    entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end)
    ).toList();
  }
}

/// Log entry data class
@immutable
class ColorLogEntry {
  final DateTime timestamp;
  final ColorLogEventType? eventType;
  final String? hexColor;
  final String? source;
  final String? description;
  final Map<String, dynamic> metadata;
  final String sessionId;

  const ColorLogEntry({
    required this.timestamp,
    this.eventType,
    this.hexColor,
    this.source,
    this.description,
    required this.metadata,
    required this.sessionId,
  });

  Map<String, dynamic> toJson(bool includeMetadata) {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType?.name,
      'hexColor': hexColor,
      'source': source,
      'description': description,
      'sessionId': sessionId,
      if (includeMetadata) 'metadata': metadata,
    };
  }
}

/// Event types for color picker logging
enum ColorLogEventType {
  colorSelection,
  paletteCreated,
  paletteDeleted,
  settingsChanged,
  themeChanged,
  exportLogs,
  clearLogs,
  performanceIssue,
  error;
}

/// Export format options
enum ColorLogFormat {
  json,
  csv,
  text;
}