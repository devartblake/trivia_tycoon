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
  _ConfettiPhysicsControlsState createState() => _ConfettiPhysicsControlsState();
}

class _ConfettiPhysicsControlsState extends State<ConfettiPhysicsControls> {
  late double speed;
  late double gravity;
  late double wind;

  @override
  void initState(){
    super.initState();
    speed = widget.speed;
    gravity = widget.gravity;
    wind = widget.wind;
  }

  void _updatePhysics() {
    widget.onChanged(speed, gravity, wind);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Speed: ${speed.toStringAsFixed(2)}"),
        Slider(
            value: speed,
            min: 0.1,
            max: 10.0,
            onChanged: (value) {
              setState(() => speed = value);
              _updatePhysics();
            },
        ),
        Text("Gravity: ${gravity.toStringAsFixed(2)}"),
        Slider(
            value: gravity,
            min: 0.0,
            max: 5.0,
            onChanged: (value){
              setState(() => gravity = value);
              _updatePhysics();
          },
        ),
        Text("Wind: ${wind.toStringAsFixed(2)}"),
        Slider(
          value: wind,
          min: -2.0,
          max: 2.0,
          onChanged: (value) {
            setState(() => wind = value);
            _updatePhysics();
          },
        ),
      ],
    );
  }
}