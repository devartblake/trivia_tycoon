import 'package:flutter/material.dart';

/// Tiny logger wrapper so you can turn logs on/off from config.
class MultiplayerLogger {
  final bool enabled;
  const MultiplayerLogger({this.enabled = false});

  void d(String msg) {
    if (enabled) {
      // ignore: avoid_print
      debugPrint('[MP][D] $msg');
    }
  }

  void i(String msg) {
    if (enabled) {
      // ignore: avoid_print
      debugPrint('[MP][I] $msg');
    }
  }

  void w(String msg) {
    if (enabled) {
      // ignore: avoid_print
      debugPrint('[MP][W] $msg');
    }
  }

  void e(String msg, [Object? err, StackTrace? st]) {
    if (enabled) {
      // ignore: avoid_print
      debugPrint('[MP][E] $msg ${err != null ? ' err=$err' : ''}');
      if (st != null) {
        // ignore: avoid_print
        debugPrint(st.toString());
      }
    }
  }
}
