import 'package:flutter/material.dart';

import 'synaptix_toast.dart';
import 'synaptix_toast_helper.dart';

/// App-level presenter for Synaptix toasts.
///
/// Wire [navigatorKey] into the root router and [scaffoldMessengerKey] into
/// MaterialApp so notifications can be launched from services, providers, and
/// screens without depending on a local Scaffold context.
class SynaptixToastService {
  SynaptixToastService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'SynaptixToastNavigatorKey');

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(
    debugLabel: 'SynaptixToastScaffoldMessengerKey',
  );

  static BuildContext? get currentContext =>
      navigatorKey.currentContext ?? scaffoldMessengerKey.currentContext;

  static Future<T?> show<T extends Object?>(
    SynaptixToast<T> toast, {
    BuildContext? context,
    bool useSnackBarFallback = true,
  }) {
    final toastContext = context ?? navigatorKey.currentContext;
    if (toastContext != null && toastContext.mounted) {
      return toast.show(toastContext);
    }

    if (useSnackBarFallback) {
      _showSnackBarFallback(toast);
    }
    return Future<T?>.value();
  }

  static Future<void> success({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) async {
    await show<void>(
      SynaptixToastHelper.createSuccess(
        title: title,
        message: message,
        duration: duration,
      ),
      context: context,
    );
  }

  static Future<void> info({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    BuildContext? context,
  }) async {
    await show<void>(
      SynaptixToastHelper.createInformation(
        title: title,
        message: message,
        duration: duration,
      ),
      context: context,
    );
  }

  static Future<void> error({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    BuildContext? context,
  }) async {
    await show<void>(
      SynaptixToastHelper.createError(
        title: title,
        message: message,
        duration: duration,
      ),
      context: context,
    );
  }

  static Future<void> reward({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? rewardType,
    String? rewardAmount,
    BuildContext? context,
  }) async {
    await show<void>(
      SynaptixToastHelper.createReward(
        title: title,
        message: message,
        duration: duration,
        rewardType: rewardType,
        rewardAmount: rewardAmount,
      ),
      context: context,
    );
  }

  static Future<void> compact({
    required String message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) async {
    await show<void>(
      SynaptixToastHelper.createCompact(
        message: message,
        icon: icon,
        color: color,
        duration: duration,
      ),
      context: context,
    );
  }

  static void _showSnackBarFallback(SynaptixToast<dynamic> toast) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_fallbackMessage(toast)),
        duration: toast.duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _fallbackColor(toast.toastType),
      ),
    );
  }

  static String _fallbackMessage(SynaptixToast<dynamic> toast) {
    final parts = <String>[
      if (toast.title?.isNotEmpty == true) toast.title!,
      if (toast.message?.isNotEmpty == true) toast.message!,
    ];
    return parts.isEmpty ? 'Notification' : parts.join('\n');
  }

  static Color _fallbackColor(SynaptixToastType type) {
    switch (type) {
      case SynaptixToastType.success:
        return Colors.green.shade700;
      case SynaptixToastType.error:
        return Colors.red.shade700;
      case SynaptixToastType.info:
        return Colors.blue.shade700;
      case SynaptixToastType.reward:
        return Colors.orange.shade700;
      case SynaptixToastType.custom:
        return Colors.grey.shade900;
    }
  }
}
