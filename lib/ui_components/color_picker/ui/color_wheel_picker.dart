import 'dart:math';
import 'package:flutter/material.dart';

class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;
  final Function(Color) onColorChanged;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    required this.onColorChanged,
    required Color selectedColor,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late double _hue;
  double _saturation = 1.0;
  double _brightness = 0.5;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _brightness = hsl.lightness;
  }

  Color get _currentColor => HSLColor.fromAHSL(1.0, _hue, _saturation, _brightness).toColor();

  void _updateColor() {
    final color = _currentColor;
    widget.onColorSelected(color);
    widget.onColorChanged(color);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🎡 Hue Color Wheel Ring
        SizedBox(
          width: 120,
          height: 120,
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset center = box.size.center(Offset.zero);
              final Offset local = box.globalToLocal(details.globalPosition);
              final double dx = local.dx - center.dx;
              final double dy = local.dy - center.dy;
              final double angle = (atan2(dy, dx) * 180 / pi + 360) % 360;
              setState(() => _hue = angle);
              _updateColor();
            },
            child: CustomPaint(
              painter: _HueRingPainter(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// 🎛️ Sliders
        Column(
          children: [
            _buildSlider("Saturation", _saturation, (val) {
              setState(() => _saturation = val);
              _updateColor();
            }),
            _buildSlider("Brightness", _brightness, (val) {
              setState(() => _brightness = val);
              _updateColor();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text(label),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0,
          max: 1,
        ),
      ],
    );
  }
}

class _HueRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: List.generate(360, (i) => HSLColor.fromAHSL(1, i.toDouble(), 1, 0.5).toColor()),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawCircle(center, radius - 10, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
