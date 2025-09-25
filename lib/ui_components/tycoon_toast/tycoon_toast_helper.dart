import 'tycoon_toast.dart';
import 'package:flutter/material.dart';
import 'Toast_theme_manager.dart';

class TycoonToastHelper {
  /// Get a modern success notification toast
  static TycoonToast createSuccess({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return TycoonToast(
      title: title ?? 'Success',
      message: message,
      icon: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle_rounded,
          color: Colors.green[300],
          size: 24,
        ),
      ),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green[600]!.withOpacity(0.9),
          Colors.green[400]!.withOpacity(0.8),
        ],
      ),
      toastType: TycoonToastType.success,
      duration: duration,
      borderRadius: BorderRadius.circular(16),
    );
  }

  /// Get a modern information notification toast
  static TycoonToast createInformation({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    return TycoonToast(
      title: title ?? 'Info',
      message: message,
      icon: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_rounded,
          color: Colors.blue[300],
          size: 24,
        ),
      ),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue[600]!.withOpacity(0.9),
          Colors.blue[400]!.withOpacity(0.8),
        ],
      ),
      toastType: TycoonToastType.info,
      duration: duration,
      borderRadius: BorderRadius.circular(16),
    );
  }

  /// Get a modern error notification toast
  static TycoonToast createError({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    return TycoonToast(
      title: title ?? 'Error',
      message: message,
      icon: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_rounded,
          color: Colors.red[300],
          size: 24,
        ),
      ),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red[600]!.withOpacity(0.9),
          Colors.red[400]!.withOpacity(0.8),
        ],
      ),
      toastType: TycoonToastType.error,
      duration: duration,
      borderRadius: BorderRadius.circular(16),
    );
  }

  /// Get a modern reward notification toast with special effects
  static TycoonToast createReward({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? rewardType,
    String? rewardAmount,
  }) {
    return TycoonToast(
      title: title ?? 'Reward Claimed!',
      message: message,
      icon: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber[400]!, Colors.orange[400]!],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.card_giftcard_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.amber[600]!.withOpacity(0.95),
          Colors.orange[500]!.withOpacity(0.9),
          Colors.pink[400]!.withOpacity(0.85),
        ],
      ),
      toastType: TycoonToastType.reward,
      duration: duration,
      shouldIconPulse: true,
      borderRadius: BorderRadius.circular(20),
      boxShadows: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.3),
          blurRadius: 25,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  /// Get a weekly reward toast specifically for the RewardScreen
  static TycoonToast createWeeklyReward({
    required int day,
    required String rewardType,
    required String rewardAmount,
    Duration duration = const Duration(seconds: 4),
  }) {
    IconData rewardIcon;
    Color rewardColor;

    switch (rewardType.toLowerCase()) {
      case 'coins':
        rewardIcon = Icons.monetization_on_rounded;
        rewardColor = Colors.amber;
        break;
      case 'gems':
        rewardIcon = Icons.diamond_rounded;
        rewardColor = Colors.blue;
        break;
      case 'spins':
        rewardIcon = Icons.casino_rounded;
        rewardColor = Colors.purple;
        break;
      case 'boost':
        rewardIcon = Icons.flash_on_rounded;
        rewardColor = Colors.orange;
        break;
      default:
        rewardIcon = Icons.card_giftcard_rounded;
        rewardColor = Colors.amber;
    }

    return TycoonToast(
      title: 'Day $day Claimed!',
      message: '+$rewardAmount $rewardType earned',
      icon: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              rewardColor.withOpacity(0.8),
              rewardColor.withOpacity(0.6),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: rewardColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          rewardIcon,
          color: Colors.white,
          size: 20,
        ),
      ),
      mainButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              'Continue Weekly Progress',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      backgroundGradient: TycoonToastThemeManager.getGradientForEvent(rewardType.toLowerCase()),
      toastType: TycoonToastType.reward,
      duration: duration,
      shouldIconPulse: true,
      borderRadius: BorderRadius.circular(16),
      tycoonToastPosition: TycoonToastPosition.top,
      margin: EdgeInsets.fromLTRB(16, 40, 16, 16),
      padding: EdgeInsets.all(16),
      boxShadows: [
        BoxShadow(
          color: rewardColor.withOpacity(0.3),
          blurRadius: 20,
          offset: Offset(0, 8),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  /// Get a toast with custom action button
  static TycoonToast createAction({
    required String message,
    required Widget button,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    return TycoonToast(
      title: title,
      message: message,
      mainButton: button,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.indigo[600]!.withOpacity(0.9),
          Colors.purple[500]!.withOpacity(0.8),
        ],
      ),
      toastType: TycoonToastType.custom,
      duration: duration,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(16),
    );
  }

  /// Get a toast for loading states with progress
  static TycoonToast createLoading({
    required String message,
    String? title,
    Duration? duration,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
  }) {
    return TycoonToast(
      title: title ?? 'Loading...',
      message: message,
      icon: Container(
        padding: EdgeInsets.all(2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan[300]!),
            backgroundColor: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
      showProgressIndicator: true,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor ?? Colors.white.withOpacity(0.2),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.cyan[600]!.withOpacity(0.9),
          Colors.teal[500]!.withOpacity(0.8),
        ],
      ),
      toastType: TycoonToastType.info,
      duration: duration,
      shouldIconPulse: false,
      borderRadius: BorderRadius.circular(16),
      isDismissible: false,
      padding: EdgeInsets.all(16),
    );
  }

  /// Get a toast for user input
  static TycoonToast createInputToast({
    required Form textForm,
    String? title,
  }) {
    return TycoonToast(
      title: title,
      userInputForm: textForm,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.teal[600]!.withOpacity(0.9),
          Colors.green[500]!.withOpacity(0.8),
        ],
      ),
      toastType: TycoonToastType.custom,
      duration: null,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(16),
    );
  }

  /// Get a compact notification for quick feedback
  static TycoonToast createCompact({
    required String message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 2),
  }) {
    return TycoonToast(
      message: message,
      icon: icon != null
          ? Icon(icon, color: Colors.white, size: 18)
          : null,
      backgroundGradient: LinearGradient(
        colors: [
          (color ?? Colors.grey).withOpacity(0.9),
          (color ?? Colors.grey).withOpacity(0.7),
        ],
      ),
      toastType: TycoonToastType.custom,
      duration: duration,
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.all(12),
    );
  }
}