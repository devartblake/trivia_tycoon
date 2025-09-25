import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorSliderPicker extends StatefulWidget {
  final Color initialColor;
  final Color color;
  final Function(Color) onColorChanged;

  const ColorSliderPicker({
    super.key,
    required this.initialColor,
    required this.color,
    required this.onColorChanged,
  });

  @override
  State<ColorSliderPicker> createState() => _ColorSliderPickerState();
}

class _ColorSliderPickerState extends State<ColorSliderPicker> {
  double _hue = 0.0;
  double _saturation = 1.0;
  double _lightness = 0.5;
  double _alpha = 1.0;

  @override
  void initState() {
    super.initState();
    _updateFromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(ColorSliderPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _updateFromColor(widget.color);
    }
  }

  void _updateFromColor(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    setState(() {
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _lightness = hsl.lightness;
      _alpha = color.alpha / 255.0;
    });
  }

  void _updateColor() {
    final Color newColor = HSLColor.fromAHSL(_alpha, _hue, _saturation, _lightness).toColor();
    widget.onColorChanged(newColor);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModernSlider(
            "Hue",
            Icons.color_lens_rounded,
            _hue,
            0,
            360,
                (value) {
              HapticFeedback.selectionClick();
              setState(() => _hue = value);
              _updateColor();
            },
            _getHueGradient(),
            colorScheme,
          ),

          const SizedBox(height: 12),

          _buildModernSlider(
            "Saturation",
            Icons.water_drop_outlined,
            _saturation,
            0,
            1,
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
            "Lightness",
            Icons.brightness_6_rounded,
            _lightness,
            0,
            1,
                (value) {
              HapticFeedback.selectionClick();
              setState(() => _lightness = value);
              _updateColor();
            },
            _getLightnessGradient(),
            colorScheme,
          ),

          const SizedBox(height: 12),

          _buildModernSlider(
            "Opacity",
            Icons.opacity_rounded,
            _alpha,
            0,
            1,
                (value) {
              HapticFeedback.selectionClick();
              setState(() => _alpha = value);
              _updateColor();
            },
            _getAlphaGradient(),
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSlider(
      String title,
      IconData icon,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      Gradient trackGradient,
      ColorScheme colorScheme,
      ) {
    String displayValue;
    if (title == "Hue") {
      displayValue = "${value.toInt()}°";
    } else if (title == "Opacity") {
      displayValue = "${(value * 100).toInt()}%";
    } else {
      displayValue = "${(value * 100).toInt()}%";
    }

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
                  displayValue,
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

          // Custom Gradient Slider
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                // Track background
                Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 7.5),
                  decoration: BoxDecoration(
                    gradient: trackGradient,
                    borderRadius: BorderRadius.circular(2.5),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    thumbShape: _CustomSliderThumb(colorScheme.primary),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    overlayColor: colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
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

  Gradient _getHueGradient() {
    return LinearGradient(
      colors: [
        const HSLColor.fromAHSL(1, 0, 1, 0.5).toColor(),
        const HSLColor.fromAHSL(1, 60, 1, 0.5).toColor(),
        const HSLColor.fromAHSL(1, 120, 1, 0.5).toColor(),
        const HSLColor.fromAHSL(1, 180, 1, 0.5).toColor(),
        const HSLColor.fromAHSL(1, 240, 1, 0.5).toColor(),
        const HSLColor.fromAHSL(1, 300, 1, 0.5).toColor(),
        const HSLColor.fromAHSL(1, 360, 1, 0.5).toColor(),
      ],
    );
  }

  Gradient _getSaturationGradient() {
    return LinearGradient(
      colors: [
        HSLColor.fromAHSL(1, _hue, 0, _lightness).toColor(),
        HSLColor.fromAHSL(1, _hue, 1, _lightness).toColor(),
      ],
    );
  }

  Gradient _getLightnessGradient() {
    return LinearGradient(
      colors: [
        HSLColor.fromAHSL(1, _hue, _saturation, 0).toColor(),
        HSLColor.fromAHSL(1, _hue, _saturation, 0.5).toColor(),
        HSLColor.fromAHSL(1, _hue, _saturation, 1).toColor(),
      ],
    );
  }

  Gradient _getAlphaGradient() {
    final baseColor = HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0),
        baseColor.withOpacity(1),
      ],
    );
  }
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
