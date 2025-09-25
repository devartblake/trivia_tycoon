import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final Function(Color) onColorChanged;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onColorChanged,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker>
    with TickerProviderStateMixin {
  late double _hue;
  double _saturation = 1.0;
  double _brightness = 0.5;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _updateFromColor(widget.initialColor);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedColor != oldWidget.selectedColor) {
      _updateFromColor(widget.selectedColor);
    }
  }

  void _updateFromColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    setState(() {
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _brightness = hsl.lightness;
    });
  }

  Color get _currentColor => HSLColor.fromAHSL(1.0, _hue, _saturation, _brightness).toColor();

  void _updateColor() {
    final color = _currentColor;
    widget.onColorSelected(color);
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color Wheel
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  _handleWheelInteraction(details.localPosition, context);
                },
                onTapDown: (details) {
                  _handleWheelInteraction(details.localPosition, context);
                },
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: CustomPaint(
                        size: const Size(180, 180),
                        painter: _ColorWheelPainter(
                          hue: _hue,
                          saturation: _saturation,
                          brightness: _brightness,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Saturation and Brightness Sliders
          _buildModernSlider(
            "Saturation",
            Icons.water_drop_outlined,
            _saturation,
                (value) {
              HapticFeedback.selectionClick();
              setState(() => _saturation = value);
              _updateColor();
            },
            _getSaturationGradient(),
            colorScheme,
          ),

          const SizedBox(height: 12),

          _buildModernSlider(
            "Brightness",
            Icons.brightness_6_rounded,
            _brightness,
                (value) {
              HapticFeedback.selectionClick();
              setState(() => _brightness = value);
              _updateColor();
            },
            _getBrightnessGradient(),
            colorScheme,
          ),
        ],
      ),
    );
  }

  void _handleWheelInteraction(Offset localPosition, BuildContext context) {
    final center = const Offset(90, 90); // Half of 180x180
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Check if touch is within the wheel (radius 80 to account for padding)
    if (distance <= 80) {
      final angle = (atan2(dy, dx) * 180 / pi + 360) % 360;
      final saturation = (distance / 80).clamp(0.0, 1.0);

      HapticFeedback.selectionClick();
      setState(() {
        _hue = angle;
        _saturation = saturation;
      });
      _updateColor();
    }
  }

  Widget _buildModernSlider(
      String title,
      IconData icon,
      double value,
      ValueChanged<double> onChanged,
      Gradient trackGradient,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade400,
                      Colors.purple.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${(value * 100).toInt()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 24,
            child: Stack(
              children: [
                Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: trackGradient,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: _CustomSliderThumb(_currentColor),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    overlayColor: colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Gradient _getSaturationGradient() {
    return LinearGradient(
      colors: [
        HSLColor.fromAHSL(1, _hue, 0, _brightness).toColor(),
        HSLColor.fromAHSL(1, _hue, 1, _brightness).toColor(),
      ],
    );
  }

  Gradient _getBrightnessGradient() {
    return LinearGradient(
      colors: [
        HSLColor.fromAHSL(1, _hue, _saturation, 0).toColor(),
        HSLColor.fromAHSL(1, _hue, _saturation, 0.5).toColor(),
        HSLColor.fromAHSL(1, _hue, _saturation, 1).toColor(),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double brightness;

  _ColorWheelPainter({
    required this.hue,
    required this.saturation,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw the color wheel
    for (int i = 0; i < 360; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final gradient = RadialGradient(
        colors: [
          HSLColor.fromAHSL(1, i.toDouble(), 0, brightness).toColor(),
          HSLColor.fromAHSL(1, i.toDouble(), 1, brightness).toColor(),
        ],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      final startAngle = (i - 90) * pi / 180;
      final endAngle = (i + 1 - 90) * pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }

    // Draw selection indicator
    final selectedRadius = saturation * (radius - 20) + 20;
    final selectedAngle = (hue - 90) * pi / 180;
    final selectedPosition = Offset(
      center.dx + selectedRadius * cos(selectedAngle),
      center.dy + selectedRadius * sin(selectedAngle),
    );

    // Outer ring
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(selectedPosition, 12, outerPaint);

    // Inner color
    final currentColor = HSLColor.fromAHSL(1, hue, saturation, brightness).toColor();
    final innerPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(selectedPosition, 8, innerPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(selectedPosition, 12, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _CustomSliderThumb extends SliderComponentShape {
  final Color color;

  const _CustomSliderThumb(this.color);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(20, 20);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), 10, shadowPaint);

    // Outer ring
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, outerPaint);

    // Inner color
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, innerPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 10, borderPaint);
  }
}
