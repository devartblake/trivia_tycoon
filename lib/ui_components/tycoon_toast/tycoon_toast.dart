import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'tycoon_toast_route.dart' as route;
import 'Toast_theme_manager.dart';

const String tycoonToastRouteName = '/tycoonToastRoute';

typedef TycoonToastStatusCallback = void Function(TycoonToastStatus? status);
typedef OnTycoonTap = void Function(TycoonToast toast);

enum TycoonToastType { success, error, info, reward, custom }
enum TycoonToastPosition { top, bottom }
enum TycoonToastStyle { floating, grounded }
enum TycoonToastDismissDirection { horizontal, vertical }
enum TycoonToastStatus { showing, dismissed, isAppearing, isHiding }
enum TycoonToastTransition { slide, fade, scale }
typedef TycoonThemeEvent = String;

class TycoonToast<T> extends StatefulWidget {
  TycoonToast({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.titleText,
    this.messageText,
    this.titleColor,
    this.titleSize,
    this.messageColor,
    this.messageSize,
    this.duration,
    this.mainButton,
    this.onTap,
    this.shouldIconPulse = true,
    this.maxWidth,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.textDirection = TextDirection.ltr,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor = const Color(0xFF303030),
    this.backgroundGradient,
    this.leftBarIndicatorColor,
    this.boxShadows,
    this.showProgressIndicator = false,
    this.progressIndicatorController,
    this.progressIndicatorBackgroundColor,
    this.progressIndicatorValueColor,
    this.tycoonToastPosition = TycoonToastPosition.bottom,
    this.tycoonToastStyle = TycoonToastStyle.floating,
    this.positionOffset = 0.0,
    this.dismissDirection = TycoonToastDismissDirection.vertical,
    this.forwardAnimationCurve = Curves.easeOutCirc,
    this.reverseAnimationCurve = Curves.easeOutCirc,
    this.animationDuration = const Duration(milliseconds: 600),
    TycoonToastStatusCallback? onStatusChanged,
    this.barBlur = 0.0,
    this.routeBlur,
    this.routeColor,
    this.blockBackgroundInteraction = false,
    this.safeArea = true,
    this.userInputForm,
    this.endOffset,
    this.toastType = TycoonToastType.custom,
    this.soundEffect,
    this.onShow,
    this.onDismiss,
    this.onAutoDismiss,
    this.transitionType = TycoonToastTransition.slide,
    this.themeEvent = 'general',
    this.isDismissible = true,
    this.toastRoute,
  })  : onStatusChanged = onStatusChanged ?? ((_) {}) {
    // ✅ Apply fallback seasonal gradient
    this.backgroundGradient ??= TycoonToastThemeManager.getGradientForEvent(themeEvent);
  }


  final String? title;
  final String? message;
  final Widget? icon;
  final Widget? titleText;
  final Widget? messageText;
  final Color? titleColor;
  final double? titleSize;
  final Color? messageColor;
  final double? messageSize;
  final Widget? mainButton;
  final OnTycoonTap? onTap;
  final Duration? duration;
  final bool shouldIconPulse;
  final double? maxWidth;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final TextDirection textDirection;
  final Color? borderColor;
  final double borderWidth;
  final Color backgroundColor;
  late final Gradient? backgroundGradient;
  final Color? leftBarIndicatorColor;
  final List<BoxShadow>? boxShadows;
  final bool showProgressIndicator;
  final AnimationController? progressIndicatorController;
  final Color? progressIndicatorBackgroundColor;
  final Animation<Color>? progressIndicatorValueColor;
  final TycoonToastPosition tycoonToastPosition;
  final TycoonToastStyle tycoonToastStyle;
  final double positionOffset;
  final TycoonToastDismissDirection dismissDirection;
  final Curve forwardAnimationCurve;
  final Curve reverseAnimationCurve;
  final Duration animationDuration;
  final double barBlur;
  final double? routeBlur;
  final Color? routeColor;
  final bool blockBackgroundInteraction;
  final bool safeArea;
  final Form? userInputForm;
  final Offset? endOffset;
  final bool isDismissible;
  final TycoonToastStatusCallback onStatusChanged;
  final VoidCallback? onShow;
  final VoidCallback? onDismiss;
  final VoidCallback? onAutoDismiss;
  final TycoonToastType toastType;
  final TycoonToastTransition transitionType;
  final String? soundEffect;
  final TycoonThemeEvent themeEvent;

  route.TycoonToastRoute<T?>? toastRoute;

  Future<T?> show(BuildContext context) async {
    onShow?.call();
    if (soundEffect != null) {
      final player = AudioPlayer();
      await player.setAsset(soundEffect!);
      unawaited(player.play());
    }

    toastRoute = route.showTycoonToast<T>(
      context: context,
      toast: this,
    );

    return await Navigator.of(context, rootNavigator: false)
        .push(toastRoute as Route<T>);
  }

  Future<T?> dismiss([T? result]) async {
    if (toastRoute == null) return null;

    onDismiss?.call();

    if (toastRoute!.isCurrent) {
      toastRoute!.navigator!.pop(result);
      return toastRoute!.completed;
    } else if (toastRoute!.isActive) {
      toastRoute!.navigator!.removeRoute(toastRoute!);
    }

    return null;
  }

  bool isShowing() => toastRoute?.currentStatus == TycoonToastStatus.showing;
  bool isDismissed() => toastRoute?.currentStatus == TycoonToastStatus.dismissed;
  bool isAppearing() => toastRoute?.currentStatus == TycoonToastStatus.isAppearing;
  bool isHiding() => toastRoute?.currentStatus == TycoonToastStatus.isHiding;

  @override
  State<TycoonToast> createState() => _TycoonToastState<T?>();
}

class _TycoonToastState<K extends Object?> extends State<TycoonToast<K>> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Rendered inside TycoonToastRoute
  }
}
