import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'synaptix_toast.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class SynaptixToastRoute<T extends Object?> extends OverlayRoute<T> {
  final SynaptixToast<T> tycoonToast;
  final Builder _builder;
  final Completer<T?> _transitionCompleter = Completer<T?>();
  final SynaptixToastStatusCallback? _onStatusChanged;

  Animation<double>? _filterBlurAnimation;
  Animation<Color?>? _filterColorAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _slideAnimation;
  Animation<double>? _rotationAnimation;
  Alignment? _initialAlignment;
  Alignment? _endAlignment;
  Timer? _timer;
  T? _result;
  SynaptixToastStatus? currentStatus;

  // Stack positioning
  final int _stackIndex = 0;

  SynaptixToastRoute({
    required this.tycoonToast,
    super.settings,
  })  : _builder = Builder(builder: (BuildContext innerContext) => tycoonToast),
        _onStatusChanged = tycoonToast.onStatusChanged {
    _configureAlignment(tycoonToast.tycoonToastPosition);
  }

  void _configureAlignment(SynaptixToastPosition position) {
    final stackOffset =
        _stackIndex * 0.15; // Offset each toast by 15% of screen height

    switch (position) {
      case SynaptixToastPosition.top:
        _initialAlignment = const Alignment(0.0, -2.0);
        _endAlignment = tycoonToast.endOffset != null
            ? Alignment(0.0, -0.8 + stackOffset) +
                Alignment(tycoonToast.endOffset!.dx, tycoonToast.endOffset!.dy)
            : Alignment(0.0, -0.8 + stackOffset);
        break;
      case SynaptixToastPosition.bottom:
        _initialAlignment = const Alignment(0.0, 2.0);
        _endAlignment = tycoonToast.endOffset != null
            ? Alignment(0.0, 0.8 - stackOffset) +
                Alignment(tycoonToast.endOffset!.dx, tycoonToast.endOffset!.dy)
            : Alignment(0.0, 0.8 - stackOffset);
        break;
    }
  }

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    final overlays = <OverlayEntry>[];

    if (tycoonToast.blockBackgroundInteraction) {
      overlays.add(
        OverlayEntry(
          builder: (context) => Listener(
            onPointerDown:
                tycoonToast.isDismissible ? (_) => tycoonToast.dismiss() : null,
            child: _createBackgroundOverlay(),
          ),
        ),
      );
    }

    Widget child = tycoonToast.isDismissible
        ? _getDismissibleToast(_builder)
        : _getToast();
    if (tycoonToast.safeArea) {
      child = SafeArea(child: child);
    }

    // Apply enhanced animations based on transition type
    child = _applyTransitionAnimations(child);

    overlays.add(
      OverlayEntry(
        builder: (context) => AlignTransition(
          alignment: _animation!,
          child: child,
        ),
      ),
    );

    return overlays;
  }

  Widget _applyTransitionAnimations(Widget child) {
    switch (tycoonToast.transitionType) {
      case SynaptixToastTransition.scale:
        return AnimatedBuilder(
          animation: _scaleAnimation!,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation!.value,
            child: child,
          ),
          child: child,
        );

      case SynaptixToastTransition.fade:
        return AnimatedBuilder(
          animation: _slideAnimation!,
          builder: (context, child) => Opacity(
            opacity: _slideAnimation!.value,
            child: child,
          ),
          child: child,
        );

      case SynaptixToastTransition.slide:
        // Enhanced slide with slight rotation for reward toasts
        if (tycoonToast.toastType == SynaptixToastType.reward) {
          return AnimatedBuilder(
            animation: _rotationAnimation!,
            builder: (context, child) => Transform.rotate(
              angle: _rotationAnimation!.value,
              child: Transform.scale(
                scale: math.max(0.8, _slideAnimation!.value),
                child: child,
              ),
            ),
            child: child,
          );
        }
        return child;
    }
  }

  Future<void> _playSound(String assetPath) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(assetPath);
      await player.play();
    } catch (e) {
      // Silently handle audio errors
      LogManager.debug('Toast audio error: $e');
    } finally {
      player.dispose();
    }
  }

  Widget _createBackgroundOverlay() {
    if (_filterBlurAnimation != null && _filterColorAnimation != null) {
      return AnimatedBuilder(
        animation: _filterBlurAnimation!,
        builder: (context, child) => BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _filterBlurAnimation!.value,
            sigmaY: _filterBlurAnimation!.value,
          ),
          child: Container(
            color: _filterColorAnimation!.value,
          ),
        ),
      );
    }
    return Container(color: Colors.black.withValues(alpha: 0.1));
  }

  Widget _getDismissibleToast(Widget child) {
    return Dismissible(
      direction: tycoonToast.dismissDirection ==
              SynaptixToastDismissDirection.horizontal
          ? DismissDirection.horizontal
          : (tycoonToast.tycoonToastPosition == SynaptixToastPosition.top
              ? DismissDirection.up
              : DismissDirection.down),
      key: UniqueKey(),
      onDismissed: (_) {
        tycoonToast.onDismiss?.call();
        _timer?.cancel();
        if (isActive) {
          navigator?.removeRoute(this);
        }
      },
      dismissThresholds: const {
        DismissDirection.up: 0.3,
        DismissDirection.down: 0.3,
        DismissDirection.horizontal: 0.4,
      },
      child: _getToast(),
    );
  }

  Widget _getToast() => Container(
        margin: tycoonToast.margin,
        constraints: BoxConstraints(
          maxHeight: 140, // Increased from 120 to 140 for more room
          maxWidth: MediaQuery.of(navigator!.context).size.width * 0.9,
        ),
        child: _builder,
      );

  AnimationController createAnimationController() => AnimationController(
        duration: tycoonToast.animationDuration,
        vsync: navigator!,
      );

  @override
  void install() {
    _controller = createAnimationController();
    _filterBlurAnimation = createBlurFilterAnimation();
    _filterColorAnimation = createColorFilterAnimation();
    _scaleAnimation = createScaleAnimation();
    _slideAnimation = createSlideAnimation();
    _rotationAnimation = createRotationAnimation();
    _animation = createAnimation();
    super.install();

    // Play sound effect
    if (tycoonToast.soundEffect != null) {
      unawaited(_playSound(tycoonToast.soundEffect!));
    }
  }

  Animation<Alignment>? _animation;
  AnimationController? _controller;

  Animation<Alignment> createAnimation() {
    return AlignmentTween(
      begin: _initialAlignment,
      end: _endAlignment,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: tycoonToast.forwardAnimationCurve,
        reverseCurve: tycoonToast.reverseAnimationCurve,
      ),
    );
  }

  Animation<double> createScaleAnimation() {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.elasticOut,
      ),
    );
  }

  Animation<double> createSlideAnimation() {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOutBack,
      ),
    );
  }

  Animation<double> createRotationAnimation() {
    return Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.elasticOut,
      ),
    );
  }

  Animation<double>? createBlurFilterAnimation() =>
      tycoonToast.routeBlur == null
          ? null
          : Tween<double>(begin: 0.0, end: tycoonToast.routeBlur).animate(
              CurvedAnimation(
                parent: _controller!,
                curve: const Interval(0.0, 0.35, curve: Curves.easeInOut),
              ),
            );

  Animation<Color?>? createColorFilterAnimation() =>
      tycoonToast.routeColor == null
          ? null
          : ColorTween(begin: Colors.transparent, end: tycoonToast.routeColor)
              .animate(
              CurvedAnimation(
                parent: _controller!,
                curve: const Interval(0.0, 0.35, curve: Curves.easeInOut),
              ),
            );

  @override
  TickerFuture didPush() {
    super.didPush();
    _animation!.addStatusListener(_handleStatusChanged);
    _configureTimer();
    tycoonToast.onShow?.call();
    return _controller!.forward();
  }

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        currentStatus = SynaptixToastStatus.showing;
        _onStatusChanged?.call(currentStatus);
        break;
      case AnimationStatus.dismissed:
        currentStatus = SynaptixToastStatus.dismissed;
        _onStatusChanged?.call(currentStatus);
        if (!_transitionCompleter.isCompleted) {
          _transitionCompleter.complete(_result);
        }
        break;
      case AnimationStatus.forward:
        currentStatus = SynaptixToastStatus.isAppearing;
        _onStatusChanged?.call(currentStatus);
        break;
      case AnimationStatus.reverse:
        currentStatus = SynaptixToastStatus.isHiding;
        _onStatusChanged?.call(currentStatus);
        break;
    }
  }

  void _configureTimer() {
    if (tycoonToast.duration != null) {
      _timer = Timer(tycoonToast.duration!, () {
        final routeNavigator = navigator;
        if (routeNavigator == null || !isActive) return;

        tycoonToast.onAutoDismiss?.call();
        if (isCurrent) {
          routeNavigator.pop();
        } else {
          routeNavigator.removeRoute(this);
        }
      });
    }
  }

  @override
  bool didPop(T? result) {
    super.didPop(result);
    _result = result;
    _timer?.cancel();
    _controller?.reverse();
    return true;
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (!_transitionCompleter.isCompleted) {
      _transitionCompleter.complete(_result);
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<T?> get completed => _transitionCompleter.future;
}

SynaptixToastRoute<T> showSynaptixToast<T extends Object?>({
  required BuildContext context,
  required SynaptixToast<T> toast,
}) {
  return SynaptixToastRoute<T>(
    tycoonToast: toast,
    settings: const RouteSettings(name: synaptixToastRouteName),
  );
}
