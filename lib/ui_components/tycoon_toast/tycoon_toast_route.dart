import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'tycoon_toast.dart';

class TycoonToastRoute<T> extends OverlayRoute<T> {
  final TycoonToast tycoonToast;
  final Builder _builder;
  final Completer<T> _transitionCompleter = Completer<T>();
  final TycoonToastStatusCallback? _onStatusChanged;

  Animation<double>? _filterBlurAnimation;
  Animation<Color?>? _filterColorAnimation;
  Alignment? _initialAlignment;
  Alignment? _endAlignment;
  final bool _wasDismissedBySwipe = false;
  Timer? _timer;
  T? _result;
  TycoonToastStatus? currentStatus;

  TycoonToastRoute({
    required this.tycoonToast,
    super.settings,
  })  : _builder = Builder(builder: (BuildContext innerContext) => tycoonToast),
        _onStatusChanged = tycoonToast.onStatusChanged {
    _configureAlignment(tycoonToast.tycoonToastPosition);
  }

  void _configureAlignment(TycoonToastPosition position) {
    switch (position) {
      case TycoonToastPosition.top:
        _initialAlignment = const Alignment(-1.0, -2.0);
        _endAlignment = tycoonToast.endOffset != null
            ? const Alignment(-1.0, -1.0) + Alignment(tycoonToast.endOffset!.dx, tycoonToast.endOffset!.dy)
            : const Alignment(-1.0, -1.0);
        break;
      case TycoonToastPosition.bottom:
        _initialAlignment = const Alignment(-1.0, 2.0);
        _endAlignment = tycoonToast.endOffset != null
            ? const Alignment(-1.0, 1.0) + Alignment(tycoonToast.endOffset!.dx, tycoonToast.endOffset!.dy)
            : const Alignment(-1.0, 1.0);
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
            onPointerDown: tycoonToast.isDismissible ? (_) => tycoonToast.dismiss() : null,
            child: _createBackgroundOverlay(),
          ),
        ),
      );
    }

    Widget child = tycoonToast.isDismissible ? _getDismissibleToast(_builder) : _getToast();
    if (tycoonToast.safeArea) {
      child = SafeArea(child: child);
    }

    // Themed gradient support
    final Gradient? themedGradient = _resolveGradientByType(tycoonToast.toastType);
    if (themedGradient != null) {
      tycoonToast.backgroundGradient ??= themedGradient;
    }

    // Sound support
    if (tycoonToast.soundEffect != null) {
      _playSound(tycoonToast.soundEffect!);
    }

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

  Future<void> _playSound(String assetPath) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(assetPath);
      await player.play();
    } catch (_) {}
  }

  Gradient? _resolveGradientByType(TycoonToastType type) {
    switch (type) {
      case TycoonToastType.success:
        return LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]);
      case TycoonToastType.error:
        return LinearGradient(colors: [Colors.red.shade700, Colors.red.shade400]);
      case TycoonToastType.info:
        return LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]);
      case TycoonToastType.reward:
        return LinearGradient(colors: [Colors.amber.shade700, Colors.amber.shade400]);
      default:
        return null;
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
    return Container(color: Colors.transparent);
  }

  Widget _getDismissibleToast(Widget child) {
    return Dismissible(
      direction: tycoonToast.dismissDirection == TycoonToastDismissDirection.horizontal
          ? DismissDirection.horizontal
          : (tycoonToast.tycoonToastPosition == TycoonToastPosition.top ? DismissDirection.up : DismissDirection.down),
      key: UniqueKey(),
      onDismissed: (_) => navigator?.removeRoute(this),
      child: _getToast(),
    );
  }

  Widget _getToast() => Container(margin: tycoonToast.margin, child: _builder);

  AnimationController createAnimationController() => AnimationController(
    duration: tycoonToast.animationDuration,
    vsync: navigator!,
  );

  @override
  void install() {
    _controller = createAnimationController();
    _filterBlurAnimation = createBlurFilterAnimation();
    _filterColorAnimation = createColorFilterAnimation();
    _animation = createAnimation();
    super.install();
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

  Animation<double>? createBlurFilterAnimation() => tycoonToast.routeBlur == null
      ? null
      : Tween(begin: 0.0, end: tycoonToast.routeBlur).animate(CurvedAnimation(
    parent: _controller!,
    curve: const Interval(0.0, 0.35, curve: Curves.easeInOut),
  ));

  Animation<Color?>? createColorFilterAnimation() => tycoonToast.routeColor == null
      ? null
      : ColorTween(begin: Colors.transparent, end: tycoonToast.routeColor).animate(CurvedAnimation(
    parent: _controller!,
    curve: const Interval(0.0, 0.35, curve: Curves.easeInOut),
  ));

  @override
  TickerFuture didPush() {
    super.didPush();
    _animation!.addStatusListener(_handleStatusChanged);
    _configureTimer();
    return _controller!.forward();
  }

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        currentStatus = TycoonToastStatus.showing;
        _onStatusChanged?.call(currentStatus);
        break;
      case AnimationStatus.dismissed:
        currentStatus = TycoonToastStatus.dismissed;
        _onStatusChanged?.call(currentStatus);
        break;
      case AnimationStatus.forward:
        currentStatus = TycoonToastStatus.isAppearing;
        _onStatusChanged?.call(currentStatus);
        break;
      case AnimationStatus.reverse:
        currentStatus = TycoonToastStatus.isHiding;
        _onStatusChanged?.call(currentStatus);
        break;
    }
  }

  void _configureTimer() {
    if (tycoonToast.duration != null) {
      _timer = Timer(tycoonToast.duration!, () => navigator?.pop());
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
    _transitionCompleter.complete(_result);
    _timer?.cancel();
    super.dispose();
  }

  Future<T> get completed => _transitionCompleter.future;
}

TycoonToastRoute<T> showTycoonToast<T>({
  required BuildContext context,
  required TycoonToast toast,
}) {
  return TycoonToastRoute<T>(
    tycoonToast: toast,
    settings: const RouteSettings(name: '/tycoonToastRoute'),
  );
}
