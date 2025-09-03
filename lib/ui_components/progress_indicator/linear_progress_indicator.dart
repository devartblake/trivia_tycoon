library;

import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/progress_indicator/widget/progress_bar_painter.dart';

class TycoonLinearProgressIndicator extends StatefulWidget {
  /// [value]: A double value representing the current progress percentage (0.0 to 1.0).
  final double value;

  /// [animationDuration]: An integer controlling the duration of the progress animation in milliseconds.
  final int animationDuration;

  /// /// [borderRadius]: A double value controlling the overall border radius of the progress bar.
  final double borderRadius;

  /// [borderColor]: A Color value specifying the color of the progress bar's border.
  final Color borderColor;

  /// [borderStyle]: A BorderStyle value defining the style of the border (e.g., solid, dashed).
  final BorderStyle borderStyle;

  ///borderWidth: A double value setting the width of the border.
  final double borderWidth;

  /// [backgroundColor]: A Color value representing the background color of the progress bar.
  final Color backgroundColor;

  /// [linearProgressBarBorderRadius]: A double value specifically adjusting the border radius of the linear progress bar element within the overall progress bar.
  final double linearProgressBarBorderRadius;

  /// [minHeight]: A double value setting the minimum height of the progress bar.
  final double minHeight;

  /// [colorLinearProgress]: A Color value indicating the color of the filled progress portion.
  final Color colorLinearProgress;

  /// [onProgressChanged]: A callback function that is triggered when the progress value changes.
  final ValueChanged<double>? onProgressChanged;

  /// [percentTextStyle]: A TextStyle value specifying the text style for the percentage text.
  final TextStyle? percentTextStyle;

  /// [showPercent]: A bool value indicating whether to show the percentage text or not.
  final bool showPercent;

  /// [progressAnimationCurve]: A Curve value specifying the curve for the progress animation.
  final Curve progressAnimationCurve;

  /// [alignment]: An AlignmentGeometry value specifying the alignment of the progress bar within its container.
  final AlignmentGeometry alignment;

  /// [maxValue]: A double value representing the maximum value for the progress bar.
  ///
  /// Defaults 0 to 1.0.
  ///
  /// You can set this value to more than 100%.
  final double maxValue;

  /// [gradientColors]: A List<Color> value specifying the colors for the gradient fill of the progress bar.
  final List<Color>? gradientColors;

  /// [trailingXpIcon]: A widget (usually an Icon or Image) that appears when progress is complete.
  final Widget? trailingXpIcon;

  /// [animateXpOnComplete]: Whether to animate the XP icon when progress reaches max.
  final bool animateXpOnComplete;

  final bool showGlowOnComplete;

  const TycoonLinearProgressIndicator({
    super.key,
    required this.value,
    this.animationDuration = 500,
    this.borderRadius = 0,
    this.borderColor = Colors.black,
    this.borderStyle = BorderStyle.solid,
    this.borderWidth = 1,
    this.backgroundColor = Colors.grey,
    this.linearProgressBarBorderRadius = 0,
    this.colorLinearProgress = Colors.blue,
    this.minHeight = 20,
    this.onProgressChanged,
    this.percentTextStyle,
    this.showPercent = false,
    this.progressAnimationCurve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.maxValue = 1.0,
    this.gradientColors,
    this.showGlowOnComplete = false,
    this.trailingXpIcon,
    this.animateXpOnComplete = true,
  });

  @override
  State<TycoonLinearProgressIndicator> createState() =>
      _TycoonLinearProgressIndicatorState();
}

class _TycoonLinearProgressIndicatorState
    extends State<TycoonLinearProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _xpPulseController;
  late Animation<double> _xpPulseAnimation;
  late double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
    );
    _xpPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _xpPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _xpPulseController, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  void _updateAnimation() {
    final clampedValue = widget.value.clamp(0.0, widget.maxValue);
    final normalizedValue = (clampedValue / widget.maxValue).clamp(0.0, 1.0);
    final normalizedPreviousValue =
    (_previousValue / widget.maxValue).clamp(0.0, 1.0);

    _animation = Tween<double>(
      begin: normalizedPreviousValue,
      end: normalizedValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.progressAnimationCurve,
    ))
      ..addListener(() {
        setState(() {});
        if (widget.onProgressChanged != null) {
          widget.onProgressChanged!(clampedValue);
        }

        if (widget.animateXpOnComplete && normalizedValue >= 1.0) {
          _xpPulseController.repeat(reverse: true);
        } else {
          _xpPulseController.stop();
        }
      });
    _animationController.forward(from: 0);
    _previousValue = clampedValue;
  }

  void _refreshAnimation() {
    final clampedValue = widget.value.clamp(0.0, widget.maxValue);
    final normalizedValue = (clampedValue / widget.maxValue).clamp(0.0, 1.0);

    _animation = Tween<double>(
      begin: 0,
      end: normalizedValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.progressAnimationCurve,
    ));

    _animationController.forward(from: 0);
    _previousValue = clampedValue;
  }

  @override
  void didUpdateWidget(TycoonLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.maxValue != widget.maxValue) {
      _updateAnimation();
    }
  }

  void _resetAnimation() {
    _animationController.reset();
    _refreshAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _xpPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _resetAnimation,
      child: SizedBox(
        height: widget.minHeight,
        child: Stack(
          children: [
            CustomPaint(
              painter: ProgressBarPainter(
                value: _animation.value,
                borderRadius: widget.borderRadius,
                borderColor: widget.borderColor,
                borderStyle: widget.borderStyle,
                borderWidth: widget.borderWidth,
                backgroundColor: widget.backgroundColor,
                valueColor: widget.colorLinearProgress,
                linearProgressBarBorderRadius:
                widget.linearProgressBarBorderRadius,
                gradientColors: widget.gradientColors,
              ),
              size: Size.infinite,
            ),
            if (widget.showPercent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Align(
                  alignment: widget.alignment,
                  child: Text(
                    '${(_animation.value * widget.maxValue * 100).toStringAsFixed(1)}%',
                    style: widget.percentTextStyle,
                  ),
                ),
              ),

            if (widget.showGlowOnComplete && _animation.value >= 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: widget.colorLinearProgress.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (widget.trailingXpIcon != null && _animation.value >= 1.0)
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: ScaleTransition(
                  scale: _xpPulseAnimation,
                  child: widget.trailingXpIcon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}