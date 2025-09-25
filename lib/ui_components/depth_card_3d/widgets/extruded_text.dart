import 'package:flutter/material.dart';

/// Faux-3D text by stacking offset layers (dependency-free).
class ExtrudedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int depth;
  final double elevation;
  final Offset tilt;
  final bool shine;
  final Duration shineDuration;
  final Color? faceColor;
  final Color? sideColor;
  final bool stroke; // optional outline under face

  const ExtrudedText({
    super.key,
    required this.text,
    this.style = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
    ),
    this.depth = 12,
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
    final baseFace = faceColor ?? style.color ?? Colors.white;
    final baseSide = sideColor ?? HSLColor.fromColor(baseFace).withLightness(0.25).toColor();

    final layers = <Widget>[];

    // Back to front: sides first
    for (int i = depth; i >= 1; i--) {
      final dx = i * elevation * (0.25 + 0.75 * tilt.dx);
      final dy = i * elevation * (0.35 + 0.65 * tilt.dy);

      layers.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Text(
            text,
            style: style.copyWith(
              color: Color.alphaBlend(
                baseSide.withOpacity(0.85),
                baseFace.withOpacity(0.15),
              ),
            ),
          ),
        ),
      );
    }

    Widget faceText = Text(text, style: style.copyWith(color: baseFace));

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
      layers.add(
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
      layers.add(faceText);
    }

    return Stack(children: layers);
  }
}
