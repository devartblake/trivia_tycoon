import 'package:flutter/material.dart';
import '../models/qr_matrix.dart';

class QrPainter extends CustomPainter {
  final QrMatrix matrix;
  final Color dotColor;
  final Color backgroundColor;
  final double gap; // for rounded style spacing

  QrPainter({
    required this.matrix,
    this.dotColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.gap = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('=== QrPainter Debug ===');
    debugPrint('Canvas size: ${size.width}x${size.height}');
    debugPrint('Matrix size: ${matrix.size}');
    debugPrint('Dot color: $dotColor');
    debugPrint('Background color: $backgroundColor');
    debugPrint('Gap: $gap');

    final paint = Paint()..color = dotColor;
    final backgroundPaint = Paint()..color = backgroundColor;

    // Fill background
    canvas.drawRect(Offset.zero & size, backgroundPaint);
    debugPrint('Background drawn');

    // Check if size is valid
    if (size.width <= 0 || size.height <= 0) {
      debugPrint('ERROR: Invalid canvas size!');
      return;
    }

    if (matrix.size <= 0) {
      debugPrint('ERROR: Invalid matrix size!');
      return;
    }

    final moduleSize = size.width / matrix.size;
    debugPrint('Module size: $moduleSize');

    int dotsDrawn = 0;
    int totalModules = 0;

    for (int y = 0; y < matrix.size; y++) {
      for (int x = 0; x < matrix.size; x++) {
        totalModules++;

      try {
        if (matrix.get(x, y)) {
          final left = x * moduleSize + gap / 2;
          final top = y * moduleSize + gap / 2;
          final sizeAdjusted = moduleSize - gap;

          final rect = Rect.fromLTWH(left, top, sizeAdjusted, sizeAdjusted);
          final rrect = RRect.fromRectAndRadius(rect, Radius.circular(gap / 2));
          canvas.drawRRect(rrect, paint);
          dotsDrawn++;
        }
      } catch (e) {
        debugPrint('ERROR at position ($x, $y): $e');
        }
      }
    }

    debugPrint('Drew $dotsDrawn dots out of $totalModules modules');
    debugPrint('======================');
  }

  @override
  bool shouldRepaint(covariant QrPainter oldDelegate) {
    final shouldRepaint = oldDelegate.matrix != matrix ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gap != gap;

    if (shouldRepaint) {
      debugPrint('QrPainter: Should repaint = true');
    }

    return shouldRepaint;
  }
}
