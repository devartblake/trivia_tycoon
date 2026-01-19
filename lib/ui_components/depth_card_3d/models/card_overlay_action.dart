import 'package:flutter/material.dart';

class CardOverlayAction {
  final String? title;
  final String? name;
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onTap;
  final String tooltip;

  const CardOverlayAction({
    required this.icon,
    required this.onPressed,
    required this.onTap,
    required this.tooltip,
    this.title,
    this.name,
  });

  /// Builds the action button widget with glass morphism effect
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
