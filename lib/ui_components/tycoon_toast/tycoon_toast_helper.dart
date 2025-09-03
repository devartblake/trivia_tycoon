import 'tycoon_toast.dart';
import 'package:flutter/material.dart';

class TycoonToastHelper {
  /// Get a success notification toast.
  static TycoonToast createSuccess({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return TycoonToast(
      title: title,
      message: message,
      icon: Icon(Icons.check_circle, color: Colors.green[300]),
      leftBarIndicatorColor: Colors.green[300],
      backgroundGradient: LinearGradient(
        colors: [Colors.green[700]!, Colors.green[400]!],
      ),
      soundEffect: 'assets/sounds/success.mp3',
      toastType: TycoonToastType.success,
      duration: duration,
    );
  }

  /// Get an information notification toast.
  static TycoonToast createInformation({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return TycoonToast(
      title: title,
      message: message,
      icon: Icon(Icons.info_outline, size: 28.0, color: Colors.blue[300]),
      leftBarIndicatorColor: Colors.blue[300],
      backgroundGradient: LinearGradient(
        colors: [Colors.blue[700]!, Colors.blue[300]!],
      ),
      soundEffect: 'assets/sounds/info.mp3',
      toastType: TycoonToastType.info,
      duration: duration,
    );
  }

  /// Get an error notification toast.
  static TycoonToast createError({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return TycoonToast(
      title: title,
      message: message,
      icon: Icon(Icons.warning, size: 28.0, color: Colors.red[300]),
      leftBarIndicatorColor: Colors.red[300],
      backgroundGradient: LinearGradient(
        colors: [Colors.red[800]!, Colors.red[400]!],
      ),
      soundEffect: 'assets/sounds/error.mp3',
      toastType: TycoonToastType.error,
      duration: duration,
    );
  }

  /// Get a toast that can receive a user action through a button.
  static TycoonToast createAction({
    required String message,
    required Widget button,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return TycoonToast(
      title: title,
      message: message,
      mainButton: button,
      backgroundGradient: LinearGradient(
        colors: [Colors.indigo[700]!, Colors.indigo[400]!],
      ),
      soundEffect: 'assets/sounds/action.mp3',
      toastType: TycoonToastType.custom,
      duration: duration,
    );
  }

  /// Get a toast that shows the progress of an async computation.
  static TycoonToast createLoading({
    required String message,
    required LinearProgressIndicator linearProgressIndicator,
    String? title,
    Duration duration = const Duration(seconds: 3),
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
  }) {
    return TycoonToast(
      title: title,
      message: message,
      icon: Icon(Icons.cloud_upload, color: Colors.blue[300]),
      showProgressIndicator: true,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      backgroundGradient: LinearGradient(
        colors: [Colors.cyan[800]!, Colors.cyan[300]!],
      ),
      soundEffect: 'assets/sounds/loading.mp3',
      toastType: TycoonToastType.info,
      duration: duration,
    );
  }

  /// Get a toast that shows a user input form.
  static TycoonToast createInputToast({required Form textForm}) {
    return TycoonToast(
      userInputForm: textForm,
      backgroundGradient: LinearGradient(
        colors: [Colors.teal[700]!, Colors.teal[400]!],
      ),
      soundEffect: 'assets/sounds/input.mp3',
      toastType: TycoonToastType.custom,
      duration: null,
    );
  }

  /// Get a reward-based toast.
  static TycoonToast createReward({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    return TycoonToast(
      title: title,
      message: message,
      icon: Icon(Icons.card_giftcard, size: 28.0, color: Colors.amber[300]),
      leftBarIndicatorColor: Colors.amber[300],
      backgroundGradient: LinearGradient(
        colors: [Colors.amber[800]!, Colors.amber[400]!],
      ),
      soundEffect: 'assets/sounds/reward.mp3',
      toastType: TycoonToastType.reward,
      duration: duration,
    );
  }
}
