import 'package:flutter/material.dart';

class PowerUpButtons extends StatelessWidget {
  final List<Map<String, dynamic>> powerUps;

  const PowerUpButtons({
    super.key,
    required this.powerUps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: powerUps.map((powerUp) {
        return Tooltip(
          message: powerUp['hint'],
          child: IconButton(
            icon: Icon(powerUp['icon'], size: 32),
            onPressed: powerUp['action'],
          ),
        );
      }).toList(),
    );
  }
}
