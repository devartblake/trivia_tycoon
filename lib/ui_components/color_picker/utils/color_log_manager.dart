import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class ColorLogManager {
  static final List<String> _logEntries = [];

  static void logColorSelection(String hexColor) {
    String logEntry = "${DateTime.now()} - Selected color: $hexColor";
    _logEntries.add(logEntry);

    LogManager.log(
      "Color picker encountered invalid HEX input: $hexColor",
      level: LogLevel.warning,
      source: "ColorPicker",
    );
  }

  static Future<String> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}color_picker_logs.txt');
      await file.writeAsString(_logEntries.join("\n"));
      return file.path;
    } catch (e) {
      return "Error exporting logs: $e";
    }
  }
}