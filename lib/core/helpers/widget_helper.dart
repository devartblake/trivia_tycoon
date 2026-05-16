import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/synaptix_toast/synaptix_toast.dart';

Size? getWidgetSize(GlobalKey key) {
  final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  return renderBox?.size;
}

SynaptixToast showSuccessToast(
  BuildContext context,
  String title,
  String message, [
  Duration? duration,
]) {
  return SynaptixToast(
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

SynaptixToast showErrorToast(
    BuildContext context, String title, String message) {
  return SynaptixToast(
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
