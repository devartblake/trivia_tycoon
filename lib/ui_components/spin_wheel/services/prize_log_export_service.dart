import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/settings/app_settings.dart';
import '../models/prize_entry.dart';

class PrizeLogExportService {
  /// Export as JSON file
  static Future<File> exportToFile(List<PrizeEntry> entries) async {
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/prize_log_backup.json');
    return file.writeAsString(jsonString);
  }

  /// Import from JSON file and append to prize log
  static Future<void> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final raw = await file.readAsString();
    final List<dynamic> decoded = json.decode(raw);
    final List<PrizeEntry> entries = decoded
        .map((e) => PrizeEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Merge with existing log
    final current = await AppSettings.getPrizeLog();
    final updated = [...current, ...entries];
    await AppSettings.setPrizeLog(updated);
  }

  static Future<File> exportToCsv(List<PrizeEntry> entries) async {
    final buffer = StringBuffer();
    buffer.writeln("Prize,Timestamp");
    for (final e in entries) {
      buffer.writeln('"${e.prize}","${e.timestamp.toIso8601String()}"');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/prize_log_backup.csv');
    return file.writeAsString(buffer.toString());
  }

}
