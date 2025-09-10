import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../math/hex_orientation.dart';
import '../paint/hex_shape.dart';

class Hexagon extends StatelessWidget {
  final double radius;
  final HexOrientation orientation;
  final Gradient? gradient;
  final Color? color;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final double elevation;
  final Color shadowColor;
  final Widget? child;
  final VoidCallback? onTap;

  const Hexagon({
    super.key,
    required this.radius,
    this.orientation = HexOrientation.pointy,
    this.gradient,
    this.color,
    this.borderColor = const Color(0x44FFFFFF),
    this.borderWidth = 1.5,
    this.cornerRadius = 0.0,
    this.elevation = 0.0,
    this.shadowColor = const Color(0x33000000),
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = Size(radius * 2, orientation == HexOrientation.pointy
        ? (radius * 1.7320508) : (radius * 2));

    Widget hexWidget = SizedBox(
      width: size.width,
      height: size.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: _HexBorder(
            radius: radius,
            orientation: orientation,
            cornerRadius: cornerRadius,
          ),
          child: CustomPaint(
            painter: _HexPainter(
              radius: radius,
              orientation: orientation,
              gradient: gradient,
              color: color,
              borderColor: borderColor,
              borderWidth: borderWidth,
              cornerRadius: cornerRadius,
            ),
            child: child,
          ),
        ),
      ),
    );

    // Add elevation if specified
    if (elevation > 0) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: elevation * 2,
              spreadRadius: elevation * 0.5,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: hexWidget,
      );
    }

    return hexWidget;
  }
}

class _HexPainter extends CustomPainter {
  final double radius;
  final HexOrientation orientation;
  final Gradient? gradient;
  final Color? color;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;

  _HexPainter({
    required this.radius,
    required this.orientation,
    this.gradient,
    this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = _buildRoundedHexPath(
      center: center,
      radius: radius,
      orientation: orientation,
      cornerRadius: cornerRadius,
    );

    // Fill the hexagon
    if (gradient != null) {
      final paint = Paint()..shader = gradient!.createShader(Offset.zero & size);
      canvas.drawPath(path, paint);
    } else {
      final paint = Paint()..color = color ?? const Color(0x11222222);
      canvas.drawPath(path, paint);
    }

    // Draw border
    if (borderWidth > 0) {
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor;
      canvas.drawPath(path, border);
    }
  }

  Path _buildRoundedHexPath({
    required Offset center,
    required double radius,
    required HexOrientation orientation,
    required double cornerRadius,
  }) {
    if (cornerRadius <= 0) {
      // Use original hex path if no corner radius
      return buildHexPath(center: center, radius: radius, orientation: orientation);
    }

    // Calculate hexagon vertices
    final vertices = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (orientation == HexOrientation.pointy ? 0.0 : 30.0) + (i * 60.0);
      final radians = angle * (math.pi / 180.0);
      vertices.add(Offset(
        center.dx + radius * math.cos(radians),
        center.dy + radius * math.sin(radians),
      ));
    }

    // Build path with rounded corners
    final path = Path();
    final clampedRadius = cornerRadius.clamp(0.0, radius * 0.3); // Limit corner radius

    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];
      final prev = vertices[(i - 1 + vertices.length) % vertices.length];

      if (i == 0) {
        // Move to first point (adjusted for corner radius)
        final startPoint = _getCornerStartPoint(prev, current, next, clampedRadius);
        path.moveTo(startPoint.dx, startPoint.dy);
      }

      // Add rounded corner
      _addRoundedCorner(path, prev, current, next, clampedRadius);
    }

    path.close();
    return path;
  }

  Offset _getCornerStartPoint(Offset prev, Offset current, Offset next, double cornerRadius) {
    final toPrev = Offset(prev.dx - current.dx, prev.dy - current.dy);
    final toPrevLength = math.sqrt(toPrev.dx * toPrev.dx + toPrev.dy * toPrev.dy);
    final toPrevNorm = Offset(toPrev.dx / toPrevLength, toPrev.dy / toPrevLength);

    return Offset(
      current.dx + toPrevNorm.dx * cornerRadius,
      current.dy + toPrevNorm.dy * cornerRadius,
    );
  }

  void _addRoundedCorner(Path path, Offset prev, Offset current, Offset next, double cornerRadius) {
    // Calculate vectors from current vertex to adjacent vertices
    final toPrev = Offset(prev.dx - current.dx, prev.dy - current.dy);
    final toNext = Offset(next.dx - current.dx, next.dy - current.dy);

    final toPrevLength = math.sqrt(toPrev.dx * toPrev.dx + toPrev.dy * toPrev.dy);
    final toNextLength = math.sqrt(toNext.dx * toNext.dx + toNext.dy * toNext.dy);

    final toPrevNorm = Offset(toPrev.dx / toPrevLength, toPrev.dy / toPrevLength);
    final toNextNorm = Offset(toNext.dx / toNextLength, toNext.dy / toNextLength);

    // Calculate control points for the rounded corner
    final startPoint = Offset(
      current.dx + toPrevNorm.dx * cornerRadius,
      current.dy + toPrevNorm.dy * cornerRadius,
    );

    final endPoint = Offset(
      current.dx + toNextNorm.dx * cornerRadius,
      current.dy + toNextNorm.dy * cornerRadius,
    );

    // Draw line to start of curve, then curve to end point
    path.lineTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(current.dx, current.dy, endPoint.dx, endPoint.dy);
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.radius != radius ||
          old.orientation != orientation ||
          old.gradient != gradient ||
          old.color != color ||
          old.borderColor != borderColor ||
          old.borderWidth != borderWidth ||
          old.cornerRadius != cornerRadius;
}

class _HexBorder extends ShapeBorder {
  final double radius;
  final HexOrientation orientation;
  final double cornerRadius;

  const _HexBorder({
    required this.radius,
    required this.orientation,
    required this.cornerRadius,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => _HexBorder(
    radius: radius * t,
    orientation: orientation,
    cornerRadius: cornerRadius * t,
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    if (cornerRadius <= 0) {
      return buildHexPath(center: center, radius: radius, orientation: orientation);
    }

    // Use the same rounded path logic as the painter
    return _buildRoundedHexPath(
      center: center,
      radius: radius,
      orientation: orientation,
      cornerRadius: cornerRadius,
    );
  }

  Path _buildRoundedHexPath({
    required Offset center,
    required double radius,
    required HexOrientation orientation,
    required double cornerRadius,
  }) {
    // Calculate hexagon vertices
    final vertices = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (orientation == HexOrientation.pointy ? 0.0 : 30.0) + (i * 60.0);
      final radians = angle * (math.pi / 180.0);
      vertices.add(Offset(
        center.dx + radius * math.cos(radians),
        center.dy + radius * math.sin(radians),
      ));
    }

    final path = Path();
    final clampedRadius = cornerRadius.clamp(0.0, radius * 0.3);

    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];
      final prev = vertices[(i - 1 + vertices.length) % vertices.length];

      if (i == 0) {
        final startPoint = _getCornerStartPoint(prev, current, next, clampedRadius);
        path.moveTo(startPoint.dx, startPoint.dy);
      }

      _addRoundedCorner(path, prev, current, next, clampedRadius);
    }

    path.close();
    return path;
  }

  Offset _getCornerStartPoint(Offset prev, Offset current, Offset next, double cornerRadius) {
    final toPrev = Offset(prev.dx - current.dx, prev.dy - current.dy);
    final toPrevLength = math.sqrt(toPrev.dx * toPrev.dx + toPrev.dy * toPrev.dy);
    final toPrevNorm = Offset(toPrev.dx / toPrevLength, toPrev.dy / toPrevLength);

    return Offset(
      current.dx + toPrevNorm.dx * cornerRadius,
      current.dy + toPrevNorm.dy * cornerRadius,
    );
  }

  void _addRoundedCorner(Path path, Offset prev, Offset current, Offset next, double cornerRadius) {
    final toPrev = Offset(prev.dx - current.dx, prev.dy - current.dy);
    final toNext = Offset(next.dx - current.dx, next.dy - current.dy);

    final toPrevLength = math.sqrt(toPrev.dx * toPrev.dx + toPrev.dy * toPrev.dy);
    final toNextLength = math.sqrt(toNext.dx * toNext.dx + toNext.dy * toNext.dy);

    final toPrevNorm = Offset(toPrev.dx / toPrevLength, toPrev.dy / toPrevLength);
    final toNextNorm = Offset(toNext.dx / toNextLength, toNext.dy / toNextLength);

    final startPoint = Offset(
      current.dx + toPrevNorm.dx * cornerRadius,
      current.dy + toPrevNorm.dy * cornerRadius,
    );

    final endPoint = Offset(
      current.dx + toNextNorm.dx * cornerRadius,
      current.dy + toNextNorm.dy * cornerRadius,
    );

    path.lineTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(current.dx, current.dy, endPoint.dx, endPoint.dy);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}