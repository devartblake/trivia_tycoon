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
    final paint = Paint()..color = dotColor;
    final backgroundPaint = Paint()..color = backgroundColor;

    // Fill background
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final moduleSize = size.width / matrix.size;

    for (int y = 0; y < matrix.size; y++) {
      for (int x = 0; x < matrix.size; x++) {
        if (matrix.get(x, y)) {
          final left = x * moduleSize + gap / 2;
          final top = y * moduleSize + gap / 2;
          final sizeAdjusted = moduleSize - gap;

          final rect = Rect.fromLTWH(left, top, sizeAdjusted, sizeAdjusted);
          final rrect = RRect.fromRectAndRadius(rect, Radius.circular(gap / 2));
          canvas.drawRRect(rrect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gap != gap;
  }
}
