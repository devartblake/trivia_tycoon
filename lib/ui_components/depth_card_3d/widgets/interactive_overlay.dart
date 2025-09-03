import 'package:flutter/material.dart';
import '../models/card_overlay_action.dart';

class InteractiveOverlay extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final List<CardOverlayAction>? actions;
  final double width;
  final double height;

  const InteractiveOverlay({
    super.key,
    required this.text,
    this.onTap,
    this.actions,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          children: [
            // Bottom Text
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (actions != null)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: actions!
                      .map((action) => IconButton(
                    icon: Icon(action.icon, color: Colors.white),
                    tooltip: action.tooltip,
                    onPressed: action.onPressed,
                  ))
                      .toList(),
                ),
              ),

            // Lighting overlay
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.0,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
