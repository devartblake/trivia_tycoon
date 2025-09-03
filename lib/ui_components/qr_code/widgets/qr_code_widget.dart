import 'package:flutter/material.dart';
import '../core/qr_encoder.dart';
import '../painter/qr_painter.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final bool roundedDots;
  final Color dotColor;
  final Color backgroundColor;
  final int version; // Reserved for future version support
  final double padding; // Optional padding inside the QR area

  const QrCodeWidget({
    Key? key,
    required this.data,
    this.size = 200,
    this.roundedDots = false,
    this.dotColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.version = 1,
    this.padding = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final encoder = QrEncoder();
    final matrix = encoder.encode(data);

    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: CustomPaint(
          painter: QrPainter(
            matrix: matrix,
            dotColor: dotColor,
            backgroundColor: backgroundColor,
            gap: roundedDots ? 2.0 : 0.0, // small gap for smooth styling
          ),
        ),
      ),
    );
  }
}
