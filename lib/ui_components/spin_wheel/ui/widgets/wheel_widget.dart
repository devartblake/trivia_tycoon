import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/wheel_segment.dart';

class WheelWidget extends StatefulWidget {
  final List<WheelSegment> segments;
  final double rotationAngle;
  final int? activeIndex;

  const WheelWidget({
    super.key,
    required this.segments,
    this.rotationAngle = 0,
    this.activeIndex,
  });

  @override
  State<WheelWidget> createState() => _WheelWidgetState();
}

class _WheelWidgetState extends State<WheelWidget> {
  final Map<String, ui.Image> _loadedImages = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    for (final segment in widget.segments) {
      if (segment.imagePath != null && !_loadedImages.containsKey(segment.imagePath)) {
        final imageData = await DefaultAssetBundle.of(context).load(segment.imagePath!);
        final codec = await ui.instantiateImageCodec(imageData.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _loadedImages[segment.imagePath!] = frame.image;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(250, 250),
      painter: _WheelImagePainter(
        widget.segments,
        _loadedImages,
        widget.rotationAngle,
        widget.activeIndex,
      ),
    );
  }
}

class _WheelImagePainter extends CustomPainter {
  final List<WheelSegment> segments;
  final Map<String, ui.Image> imageMap;
  final double rotationAngle;
  final int? activeIndex;

  _WheelImagePainter(
      this.segments,
      this.imageMap,
      this.rotationAngle,
      this.activeIndex,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final anglePerSegment = 2 * pi / segments.length;
    final paint = Paint();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final startAngle = i * anglePerSegment;

      // Segment fill
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        anglePerSegment,
        true,
        paint,
      );

      // Highlight active segment
      if (i == activeIndex) {
        final highlightPaint = Paint()
          ..color = Colors.amber.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          anglePerSegment,
          true,
          highlightPaint,
        );
      }

      // Draw Image
      if (segment.imagePath != null && imageMap.containsKey(segment.imagePath)) {
        final image = imageMap[segment.imagePath]!;
        final imageSize = 40.0;

        final angle = startAngle + anglePerSegment / 2;
        final dx = center.dx + cos(angle) * radius * 0.6 - imageSize / 2;
        final dy = center.dy + sin(angle) * radius * 0.6 - imageSize / 2;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(dx, dy, imageSize, imageSize),
          Paint(),
        );
      }

      // Draw lock if exclusive
      if (segment.isExclusive) {
        final lockPaint = Paint()..color = Colors.black.withOpacity(0.5);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          anglePerSegment,
          true,
          lockPaint,
        );

        final angle = startAngle + anglePerSegment / 2;
        final iconSize = 20.0;
        final dx = center.dx + cos(angle) * radius * 0.4 - iconSize / 2;
        final dy = center.dy + sin(angle) * radius * 0.4 - iconSize / 2;

        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          fontSize: iconSize,
          textAlign: TextAlign.center,
        ))
          ..pushStyle(ui.TextStyle(color: Colors.white))
          ..addText("🔒");

        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 100));

        canvas.drawParagraph(paragraph, Offset(dx, dy));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
