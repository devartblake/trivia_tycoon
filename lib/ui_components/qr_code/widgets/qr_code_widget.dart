import 'package:flutter/material.dart';
import '../core/qr_encoder.dart';
import 'qr_painter.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final bool roundedDots;
  final Color dotColor;
  final Color backgroundColor;
  final int version;
  final double padding;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.roundedDots = false,
    this.dotColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.version = 1,
    this.padding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // DEBUG: Log input data
    debugPrint('=== QrCodeWidget Debug ===');
    debugPrint('Data: $data');
    debugPrint('Data length: ${data.length}');
    debugPrint('Size: $size');
    debugPrint('Padding: $padding');

    // Validate input
    if (data.isEmpty) {
      debugPrint('ERROR: Empty QR data!');
      return _buildErrorWidget('No data provided');
    }

    try {
      final encoder = QrEncoder();
      debugPrint('Encoder created');

      final matrix = encoder.encode(data);
      debugPrint('Matrix encoded');

      // Check if matrix is null
      if (matrix == null) {
        debugPrint('ERROR: Matrix is null!');
        return _buildErrorWidget('Encoding failed: null matrix');
      }

      // Check matrix size
      debugPrint('Matrix size: ${matrix.size}');
      if (matrix.size == 0) {
        debugPrint('ERROR: Matrix size is 0!');
        return _buildErrorWidget('Encoding failed: empty matrix');
      }

      debugPrint('QR Code ready to paint');
      debugPrint('========================');

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
              gap: roundedDots ? 2.0 : 0.0,
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR: Exception in QrCodeWidget: $e');
      debugPrint('Stack trace: $stackTrace');
      return _buildErrorWidget('Error: ${e.toString()}');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 40),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data: ${data.length} chars',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}