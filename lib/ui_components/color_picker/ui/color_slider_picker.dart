import 'package:flutter/material.dart';

class ColorSliderPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const ColorSliderPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    required Color color,
  });

  @override
  _ColorSliderPickerState createState() => _ColorSliderPickerState();
}

class _ColorSliderPickerState extends State<ColorSliderPicker> {
  double _hue = 0.0;
  double _saturation = 1.0;
  double _lightness = 0.5;

  @override
  void initState() {
    super.initState();
    _updateFromColor(widget.initialColor);
  }

  void _updateFromColor(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  void _updateColor() {
    final Color newColor = HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();
    widget.onColorChanged(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSlider("Hue", _hue, 0, 360, (value) {
          setState(() => _hue = value);
          _updateColor();
        }),
        _buildSlider("Saturation", _saturation, 0, 1, (value) {
          setState(() => _saturation = value);
          _updateColor();
        }),
        _buildSlider("Lightness", _lightness, 0, 1, (value) {
          setState(() => _lightness = value);
          _updateColor();
        }),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }
}
