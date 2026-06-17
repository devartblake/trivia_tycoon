import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    this.version = QrVersions.auto,
    this.padding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildErrorWidget('No data provided');
    }

    return SizedBox(
      width: size,
      height: size,
      child: QrImageView(
        data: data,
        version: version <= 0 ? QrVersions.auto : version,
        size: size,
        padding: EdgeInsets.all(padding),
        backgroundColor: backgroundColor,
        eyeStyle: QrEyeStyle(
          eyeShape: roundedDots ? QrEyeShape.circle : QrEyeShape.square,
          color: dotColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape:
              roundedDots ? QrDataModuleShape.circle : QrDataModuleShape.square,
          color: dotColor,
        ),
        errorStateBuilder: (context, error) {
          return _buildErrorWidget(
            error?.toString() ?? 'Could not generate QR code',
          );
        },
      ),
    );
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
