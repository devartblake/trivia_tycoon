import 'dart:math';
import 'package:flutter/material.dart';
import '../models/spin_system_models.dart';

class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;
  final double rotationAngle;
  final int? activeIndex;
  final double strokeWidth;
  final bool showLabels;

  WheelPainter({
    required this.segments,
    required this.rotationAngle,
    this.activeIndex,
    this.strokeWidth = 2.0,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth;
    final segmentAngle = 2 * pi / segments.length;

    // Draw segments
    for (int i = 0; i < segments.length; i++) {
      final startAngle = (i * segmentAngle) + rotationAngle;
      final endAngle = startAngle + segmentAngle;

      _drawSegment(
        canvas,
        center,
        radius,
        startAngle,
        endAngle,
        segments[i],
        i == activeIndex,
      );
    }

    // Draw center circle
    _drawCenterCircle(canvas, center, radius * 0.15);

    // Draw pointer
    _drawPointer(canvas, center, radius);
  }

  void _drawSegment(
      Canvas canvas,
      Offset center,
      double radius,
      double startAngle,
      double endAngle,
      WheelSegment segment,
      bool isActive,
      ) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = segment.color;

    // Create gradient for active segment
    if (isActive) {
      paint.shader = RadialGradient(
        colors: [
          segment.color.withOpacity(0.8),
          segment.color,
          segment.color.withOpacity(0.9),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }

    // Draw segment arc
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      endAngle - startAngle,
      false,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Draw segment border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = strokeWidth;

    canvas.drawPath(path, borderPaint);

    // Draw segment label if enabled
    if (showLabels) {
      _drawSegmentLabel(
        canvas,
        center,
        radius,
        startAngle,
        endAngle,
        segment.label,
        isActive,
      );
    }
  }

  void _drawSegmentLabel(
      Canvas canvas,
      Offset center,
      double radius,
      double startAngle,
      double endAngle,
      String label,
      bool isActive,
      ) {
    final midAngle = (startAngle + endAngle) / 2;
    final labelRadius = radius * 0.7;
    final labelCenter = Offset(
      center.dx + cos(midAngle) * labelRadius,
      center.dy + sin(midAngle) * labelRadius,
    );

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: isActive ? 14 : 12,
      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );

    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Rotate text if needed
    canvas.save();
    canvas.translate(labelCenter.dx, labelCenter.dy);

    // Rotate text to be readable
    double textRotation = midAngle;
    if (midAngle > pi / 2 && midAngle < 3 * pi / 2) {
      textRotation += pi; // Flip text for readability
    }

    canvas.rotate(textRotation);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawCenterCircle(Canvas canvas, Offset center, double radius) {
    // Outer circle with gradient
    final outerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.grey.shade300,
          Colors.grey.shade600,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, outerPaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.6, innerPaint);

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.2, dotPaint);
  }

  void _drawPointer(Canvas canvas, Offset center, double radius) {
    final pointerPaint = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.fill;

    final pointerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final pointerLength = radius * 0.15;
    final pointerWidth = radius * 0.08;

    final pointerPath = Path();
    pointerPath.moveTo(center.dx, center.dy - radius - strokeWidth);
    pointerPath.lineTo(center.dx - pointerWidth, center.dy - radius + pointerLength);
    pointerPath.lineTo(center.dx + pointerWidth, center.dy - radius + pointerLength);
    pointerPath.close();

    // Draw shadow
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(pointerPath, pointerShadowPaint);
    canvas.restore();

    // Draw pointer
    canvas.drawPath(pointerPath, pointerPaint);

    // Pointer border
    final pointerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(pointerPath, pointerBorderPaint);
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showLabels != showLabels;
  }
}

class WheelSegmentPainter extends CustomPainter {
  final WheelSegment segment;
  final double startAngle;
  final double sweepAngle;
  final bool isActive;
  final bool showShadow;

  WheelSegmentPainter({
    required this.segment,
    required this.startAngle,
    required this.sweepAngle,
    this.isActive = false,
    this.showShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw shadow
    if (showShadow) {
      _drawShadow(canvas, center, radius);
    }

    // Draw segment
    _drawSegment(canvas, center, radius);

    // Draw highlight for active segment
    if (isActive) {
      _drawActiveHighlight(canvas, center, radius);
    }
  }

  void _drawShadow(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final shadowPath = _createSegmentPath(center, radius + 4);
    canvas.drawPath(shadowPath, shadowPaint);
  }

  void _drawSegment(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create gradient
    paint.shader = LinearGradient(
      colors: [
        segment.color.withOpacity(0.8),
        segment.color,
        segment.color.withOpacity(0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = _createSegmentPath(center, radius);
    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);
  }

  void _drawActiveHighlight(Canvas canvas, Offset center, double radius) {
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = _createSegmentPath(center, radius - 2);
    canvas.drawPath(path, highlightPaint);
  }

  Path _createSegmentPath(Offset center, double radius) {
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(WheelSegmentPainter oldDelegate) {
    return oldDelegate.segment != segment ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.isActive != isActive ||
        oldDelegate.showShadow != showShadow;
  }
}