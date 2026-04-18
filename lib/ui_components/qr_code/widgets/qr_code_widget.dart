import 'package:flutter/material.dart';
import '../core/qr_encoder.dart';
import 'qr_painter.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

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
    LogManager.debug('=== QrCodeWidget Debug ===');
    LogManager.debug('Data: $data');
    LogManager.debug('Data length: ${data.length}');
    LogManager.debug('Size: $size');
    LogManager.debug('Padding: $padding');

    // Validate input
    if (data.isEmpty) {
      LogManager.debug('ERROR: Empty QR data!');
      return _buildErrorWidget('No data provided');
    }

    try {
      final encoder = QrEncoder();
      LogManager.debug('Encoder created');

      final matrix = encoder.encode(data);
      LogManager.debug('Matrix encoded');

      // Check matrix size
      LogManager.debug('Matrix size: ${matrix.size}');
      if (matrix.size == 0) {
        LogManager.debug('ERROR: Matrix size is 0!');
        return _buildErrorWidget('Encoding failed: empty matrix');
      }

      LogManager.debug('QR Code ready to paint');
      LogManager.debug('========================');

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
      LogManager.debug('ERROR: Exception in QrCodeWidget: $e');
      LogManager.debug('Stack trace: $stackTrace');
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
