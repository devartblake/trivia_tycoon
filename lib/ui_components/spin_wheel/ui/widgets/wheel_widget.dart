import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/spin_system_models.dart';

class WheelWidget extends StatefulWidget {
  final List<WheelSegment> segments;
  final double rotationAngle;
  final int? activeIndex;
  final double size;

  const WheelWidget({
    super.key,
    required this.segments,
    this.rotationAngle = 0,
    this.activeIndex,
    this.size = 250,
  });

  @override
  State<WheelWidget> createState() => _WheelWidgetState();
}

class _WheelWidgetState extends State<WheelWidget> {
  final Map<String, ui.Image> _loadedImages = {};
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(WheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload images if segments changed
    if (widget.segments != oldWidget.segments) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    final Map<String, ui.Image> newImages = {};

    for (final segment in widget.segments) {
      if (segment.imagePath != null) {
        // Check if already loaded
        if (_loadedImages.containsKey(segment.imagePath)) {
          newImages[segment.imagePath!] = _loadedImages[segment.imagePath!]!;
          continue;
        }

        try {
          final imageData = await DefaultAssetBundle.of(context).load(segment.imagePath!);
          final codec = await ui.instantiateImageCodec(
            imageData.buffer.asUint8List(),
            // Optimize image size for better performance
            targetWidth: 80,
            targetHeight: 80,
          );
          final frame = await codec.getNextFrame();
          newImages[segment.imagePath!] = frame.image;
        } catch (e) {
          debugPrint('Failed to load image: ${segment.imagePath}');
        }
      }
    }

    if (mounted) {
      setState(() {
        _loadedImages.clear();
        _loadedImages.addAll(newImages);
        _imagesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    // Clean up loaded images
    for (final image in _loadedImages.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _WheelImagePainter(
          segments: widget.segments,
          imageMap: _loadedImages,
          rotationAngle: widget.rotationAngle,
          activeIndex: widget.activeIndex,
          imagesLoaded: _imagesLoaded,
        ),
      ),
    );
  }
}

class _WheelImagePainter extends CustomPainter {
  final List<WheelSegment> segments;
  final Map<String, ui.Image> imageMap;
  final double rotationAngle;
  final int? activeIndex;
  final bool imagesLoaded;

  // Cache paints for better performance
  static final Paint _segmentPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.15)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  _WheelImagePainter({
    required this.segments,
    required this.imageMap,
    required this.rotationAngle,
    required this.activeIndex,
    required this.imagesLoaded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8; // Account for shadow
    final anglePerSegment = 2 * pi / segments.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Draw shadow first
    _drawWheelShadow(canvas, center, radius);

    // Draw segments
    for (int i = 0; i < segments.length; i++) {
      _drawSegment(canvas, center, radius, i, anglePerSegment);
    }

    // Draw center circle
    _drawCenterCircle(canvas, center);

    canvas.restore();
  }

  void _drawWheelShadow(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center.translate(2, 4), // Shadow offset
      radius,
      _shadowPaint,
    );
  }

  void _drawSegment(Canvas canvas, Offset center, double radius, int index, double anglePerSegment) {
    final segment = segments[index];
    final startAngle = index * anglePerSegment;
    final isActive = index == activeIndex;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Create gradient for segment
    final gradient = ui.Gradient.sweep(
      center,
      [
        segment.color,
        segment.color.withOpacity(0.8),
        segment.color,
      ],
      [0.0, 0.5, 1.0],
      ui.TileMode.clamp,
      startAngle,
      startAngle + anglePerSegment,
    );

    _segmentPaint.shader = gradient;

    // Draw segment
    canvas.drawArc(rect, startAngle, anglePerSegment, true, _segmentPaint);

    // Draw segment border
    _borderPaint.color = segment.color.withOpacity(0.6);
    canvas.drawArc(rect, startAngle, anglePerSegment, true, _borderPaint);

    // Highlight active segment
    if (isActive) {
      _highlightPaint.color = Colors.amber.withOpacity(0.8);
      canvas.drawArc(rect, startAngle, anglePerSegment, true, _highlightPaint);

      // Add inner highlight
      _highlightPaint.color = Colors.white.withOpacity(0.3);
      _highlightPaint.strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        startAngle,
        anglePerSegment,
        true,
        _highlightPaint,
      );
      _highlightPaint.strokeWidth = 4; // Reset
    }

    // Draw content
    _drawSegmentContent(canvas, center, radius, segment, startAngle, anglePerSegment);
  }

  void _drawSegmentContent(
      Canvas canvas,
      Offset center,
      double radius,
      WheelSegment segment,
      double startAngle,
      double anglePerSegment,
      ) {
    final angle = startAngle + anglePerSegment / 2;
    final contentRadius = radius * 0.65;
    final contentCenter = Offset(
      center.dx + cos(angle) * contentRadius,
      center.dy + sin(angle) * contentRadius,
    );

    // Draw image if available
    if (segment.imagePath != null &&
        imageMap.containsKey(segment.imagePath) &&
        imagesLoaded) {
      _drawSegmentImage(canvas, contentCenter, segment);
    }

    // Draw label
    _drawSegmentLabel(canvas, contentCenter, segment, angle);

    // Draw lock overlay for exclusive segments
    if (segment.isExclusive) {
      _drawLockOverlay(canvas, center, radius, startAngle, anglePerSegment);
    }
  }

  void _drawSegmentImage(Canvas canvas, Offset center, WheelSegment segment) {
    final image = imageMap[segment.imagePath]!;
    const imageSize = 32.0;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(
        center: center.translate(0, -8), // Offset up for label
        width: imageSize,
        height: imageSize,
      ),
      paint,
    );
  }

  void _drawSegmentLabel(Canvas canvas, Offset center, WheelSegment segment, double angle) {
    final textStyle = ui.TextStyle(
      color: _getContrastColor(segment.color),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 2,
    );

    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(segment.label);

    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 60));

    final textOffset = Offset(
      center.dx - paragraph.width / 2,
      center.dy + 8, // Below image
    );

    canvas.drawParagraph(paragraph, textOffset);
  }

  void _drawLockOverlay(
      Canvas canvas,
      Offset center,
      double radius,
      double startAngle,
      double anglePerSegment,
      ) {
    final lockPaint = Paint()..color = Colors.black.withOpacity(0.6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      anglePerSegment,
      true,
      lockPaint,
    );

    // Draw lock icon
    final angle = startAngle + anglePerSegment / 2;
    final lockCenter = Offset(
      center.dx + cos(angle) * radius * 0.65,
      center.dy + sin(angle) * radius * 0.65,
    );

    final lockBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 20,
      textAlign: TextAlign.center,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText("🔒");

    final lockParagraph = lockBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 30));

    canvas.drawParagraph(
      lockParagraph,
      Offset(
        lockCenter.dx - lockParagraph.width / 2,
        lockCenter.dy - lockParagraph.height / 2,
      ),
    );
  }

  void _drawCenterCircle(Canvas canvas, Offset center) {
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw center circle with shadow
    canvas.drawCircle(center.translate(1, 2), 20, _shadowPaint);
    canvas.drawCircle(center, 20, centerPaint);
    canvas.drawCircle(center, 20, borderPaint);
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(covariant _WheelImagePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.imagesLoaded != imagesLoaded ||
        oldDelegate.segments != segments;
  }
}