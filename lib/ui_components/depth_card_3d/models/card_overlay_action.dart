import 'package:flutter/material.dart';

class CardOverlayAction {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const CardOverlayAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });
}
