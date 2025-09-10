import 'package:flutter/rendering.dart';
import '../math/hex_metrics.dart';
import '../math/hex_orientation.dart';

class HexBorderPainter extends CustomPainter {
  final HexOrientation orientation;
  final double cornerRadius;
  final Color borderColor;
  final double strokeWidth;

  HexBorderPainter({
    required this.orientation,
    required this.borderColor,
    required this.strokeWidth,
    this.cornerRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = cornerRadius <= 0
        ? HexMetrics.pathInRect(rect, orientation)
        : HexMetrics.roundedPathInRect(rect, orientation, cornerRadius);
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexBorderPainter old) =>
      old.orientation != orientation ||
      old.borderColor != borderColor ||
      old.strokeWidth != strokeWidth ||
      old.cornerRadius != cornerRadius;
}
