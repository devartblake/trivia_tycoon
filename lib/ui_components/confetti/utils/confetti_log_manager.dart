import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ConfettiLogManager {
  static Future<void> exportLog(String logData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/confetti_performance_log.txt');

    await file.writeAsString(logData, mode: FileMode.append);
    if (kDebugMode) {
      print('log saved at: ${file.path}');
    }
  }
}