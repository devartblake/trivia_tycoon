import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/tycoon_toast/tycoon_toast.dart';

Size? getWidgetSize(GlobalKey key) {
  final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  return renderBox?.size;
}

TycoonToast showSuccessToast(
    BuildContext context,
    String title,
    String message, [
      Duration? duration,
    ]) {
  return TycoonToast(
    title: title,
    message: message,
    icon: const Icon(
      Icons.check,
      size: 28.0,
      color: Colors.white,
    ),
    duration: duration ?? const Duration(seconds: 4),
    backgroundGradient: LinearGradient(
      colors: [Colors.green[600]!, Colors.green[400]!],
    ),
    onTap: (tycoonToast) => tycoonToast.dismiss(),
  )..show(context);
}

TycoonToast showErrorToast(BuildContext context, String title, String message) {
  return TycoonToast(
    title: title,
    message: message,
    icon: const Icon(
      Icons.error,
      size: 28.0,
      color: Colors.white,
    ),
    duration: const Duration(seconds: 4),
    backgroundGradient: LinearGradient(
      colors: [Colors.red[600]!, Colors.red[400]!],
    ),
    onTap: (tycoonToast) => tycoonToast.dismiss(),
  )..show(context);
}