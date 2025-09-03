import 'package:flutter/material.dart';
import '../models/qr_scan_type.dart';

class ScanBoxOverlay extends StatelessWidget {
  final QrScanType? type;

  const ScanBoxOverlay({super.key, this.type});

  Color _getColor() {
    switch (type) {
      case QrScanType.url:
        return Colors.blueAccent;
      case QrScanType.userId:
        return Colors.deepPurple;
      case QrScanType.json:
        return Colors.orangeAccent;
      case QrScanType.plainText:
        return Colors.green;
      default:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: _getColor(), width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
