import 'package:flutter/material.dart';

import '../models/depth_card_theme.dart';

/// Faux-3D text by stacking offset layers (dependency-free).
class ExtrudedText extends StatelessWidget {
  final String text;
  final TextStyle style;

  /// Optional DepthCard theme (used by DepthCard3D). If provided, it will
  /// influence face/side colors but will not override your explicit [style].
  final DepthCardTheme? theme;

  final int layers;
  final double depth;
  final double opacity;
  final Offset tilt;

  final bool shine;
  final double elevation;
  final Duration shineDuration;

  final Color? faceColor;
  final Color? sideColor;
  final bool stroke; // optional outline under face

  const ExtrudedText({
    super.key,
    required this.text,
    required this.style,
    this.theme,
    this.layers = 6,
    this.depth = 1.2,
    this.opacity = 0.30,
    this.elevation = 1.0,
    this.tilt = Offset.zero,
    this.shine = true,
    this.shineDuration = const Duration(milliseconds: 1800),
    this.faceColor,
    this.sideColor,
    this.stroke = true,
  }) : assert(depth >= 1);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final themedFace = faceColor ?? style.color ?? Colors.white;
    final themedSide = sideColor ?? HSLColor.fromColor(themedFace).withLightness(0.25).toColor();

    final dx = tilt.dx * depth;
    final dy = tilt.dy * depth;

    final stack = <Widget>[];

    // Back to front: sides first
    for (double i = depth; i >= 1; i--) {
      final dx = i * elevation * (0.25 + 0.75 * tilt.dx);
      final dy = i * elevation * (0.35 + 0.65 * tilt.dy);

      stack.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Text(
            text,
            style: style.copyWith(
              color: Color.alphaBlend(
                themedSide.withOpacity(0.85),
                themedFace.withOpacity(0.15),
              ),
            ),
          ),
        ),
      );
    }

    Widget faceText = Text(text, style: style.copyWith(color: themedFace));

    if (shine) {
      faceText = ShaderMask(
        shaderCallback: (Rect r) {
          final g = LinearGradient(
            begin: Alignment(-1.2 + tilt.dx * 0.3, -0.8 + tilt.dy * 0.3),
            end: Alignment(1.2 + tilt.dx * 0.3, 0.8 + tilt.dy * 0.3),
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.15),
            ],
            stops: const [0.35, 0.5, 0.65],
          );
          return g.createShader(r);
        },
        blendMode: BlendMode.screen,
        child: faceText,
      );
    }

    if (stroke) {
      stack.add(
        Stack(
          children: [
            Text(
              text,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.2
                  ..color = Colors.black.withOpacity(0.45),
              ),
            ),
            faceText,
          ],
        ),
      );
    } else {
      stack.add(faceText);
    }

    // Side layers (extrusion)
    for (int i = layers; i >= 1; i--) {
      final t = i / layers;
      stack.add(
        Transform.translate(
          offset: Offset(dx * t, dy * t),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(
              color: themedSide.withOpacity(opacity * (1 - (t * 0.35))),
            ),
          ),
        ),
      );
    }

    // Face
    stack.add(
      Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: themedFace),
      ),
    );

    return Stack(children: stack);
  }
}
