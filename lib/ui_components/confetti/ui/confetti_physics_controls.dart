import 'package:flutter/material.dart';

class ConfettiPhysicsControls extends StatefulWidget {
  final double speed;
  final double gravity;
  final double wind;
  final Function(double speed, double gravity, double wind) onChanged;

  const ConfettiPhysicsControls({
    super.key,
    required this.speed,
    required this.gravity,
    required this.wind,
    required this.onChanged,
  });

  @override
  State<ConfettiPhysicsControls> createState() => _ConfettiPhysicsControlsState();
}

class _ConfettiPhysicsControlsState extends State<ConfettiPhysicsControls> {
  late double speed;
  late double gravity;
  late double wind;

  @override
  void initState() {
    super.initState();
    speed = widget.speed;
    gravity = widget.gravity;
    wind = widget.wind;
  }

  void _updatePhysics() {
    widget.onChanged(speed, gravity, wind);
  }

  Widget _buildSliderControl(String label, double value, double min, double max, Color color, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSliderControl(
          'Speed',
          speed,
          0.1,
          10.0,
          const Color(0xFF667EEA),
              (value) {
            setState(() => speed = value);
            _updatePhysics();
          },
        ),
        const SizedBox(height: 20),
        _buildSliderControl(
          'Gravity',
          gravity,
          0.0,
          5.0,
          const Color(0xFF9F7AEA),
              (value) {
            setState(() => gravity = value);
            _updatePhysics();
          },
        ),
        const SizedBox(height: 20),
        _buildSliderControl(
          'Wind',
          wind,
          -2.0,
          2.0,
          const Color(0xFF38B2AC),
              (value) {
            setState(() => wind = value);
            _updatePhysics();
          },
        ),
      ],
    );
  }
}
