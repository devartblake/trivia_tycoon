import 'package:flutter/services.dart';

class NativeDialogs {
  static const MethodChannel _channel = MethodChannel('trivia_native');

  static Future<String?> showInputDialog(String title, String message) async {
    try {
      final String? response = await _channel.invokeMethod('showInputDialog', {
        'title': title,
        'message': message,
      });
      return response;
    } catch (e) {
      print("Error showing input dialog: $e");
      return null;
    }
  }
}
