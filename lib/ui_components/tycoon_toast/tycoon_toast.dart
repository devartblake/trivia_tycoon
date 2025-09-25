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
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.textDirection = TextDirection.ltr,
    this.borderColor,
    this.borderWidth = 0.0,
    this.backgroundColor = const Color(0xFF303030),
    this.backgroundGradient,
    this.leftBarIndicatorColor,
    this.boxShadows,
    this.showProgressIndicator = false,
    this.progressIndicatorController,
    this.progressIndicatorBackgroundColor,
    this.progressIndicatorValueColor,
    this.tycoonToastPosition = TycoonToastPosition.top,
    this.tycoonToastStyle = TycoonToastStyle.floating,
    this.positionOffset = 0.0,
    this.dismissDirection = TycoonToastDismissDirection.vertical,
    this.forwardAnimationCurve = Curves.easeOutBack,
    this.reverseAnimationCurve = Curves.easeInBack,
    this.animationDuration = const Duration(milliseconds: 800),
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
    // Apply modern gradient with glassmorphism effect
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

class _TycoonToastState<K extends Object?> extends State<TycoonToast<K>>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (widget.shouldIconPulse) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.toastType == TycoonToastType.reward) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap != null ? () => widget.onTap!(widget) : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
          gradient: widget.backgroundGradient,
          border: widget.borderWidth > 0
              ? Border.all(color: widget.borderColor ?? Colors.white24, width: widget.borderWidth)
              : null,
          boxShadow: widget.boxShadows ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
          child: Stack(
            children: [
              // Glassmorphism effect
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // Shimmer effect for reward toasts
              if (widget.toastType == TycoonToastType.reward)
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(_shimmerAnimation.value * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Main content
              Padding(
                padding: widget.padding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Icon with pulse animation
                        if (widget.icon != null)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: widget.shouldIconPulse ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(8), // Reduced from 12
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8), // Reduced from 12
                                  ),
                                  child: widget.icon,
                                ),
                              );
                            },
                          ),

                        if (widget.icon != null) const SizedBox(width: 12), // Reduced from 16

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Added this
                            children: [
                              if (widget.title != null)
                                Text(
                                  widget.title!,
                                  style: TextStyle(
                                    color: widget.titleColor ?? Colors.white,
                                    fontSize: widget.titleSize ?? 14, // Reduced from 16
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1, // Added this
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (widget.title != null && widget.message != null)
                                const SizedBox(height: 2), // Reduced from 4
                              if (widget.message != null)
                                Text(
                                  widget.message!,
                                  style: TextStyle(
                                    color: widget.messageColor ?? Colors.white.withOpacity(0.9),
                                    fontSize: widget.messageSize ?? 12, // Reduced from 14
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2, // Added this
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Close button
                        if (widget.isDismissible)
                          GestureDetector(
                            onTap: () => widget.dismiss(),
                            child: Container(
                              padding: const EdgeInsets.all(6), // Reduced from 8
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6), // Reduced from 8
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white.withOpacity(0.8),
                                size: 16, // Reduced from 18
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Main button
                    if (widget.mainButton != null) ...[
                      const SizedBox(height: 12), // Reduced from 16
                      widget.mainButton!,
                    ],

                    // Progress indicator
                    if (widget.showProgressIndicator) ...[
                      const SizedBox(height: 12), // Reduced from 16
                      LinearProgressIndicator(
                        backgroundColor: widget.progressIndicatorBackgroundColor ??
                            Colors.white.withOpacity(0.2),
                        valueColor: widget.progressIndicatorValueColor ??
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],

                    // User input form
                    if (widget.userInputForm != null) ...[
                      const SizedBox(height: 12), // Reduced from 16
                      widget.userInputForm!,
                    ],
                  ],
                ),
              ),

              // Left bar indicator
              if (widget.leftBarIndicatorColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.leftBarIndicatorColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}