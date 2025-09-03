import 'package:flutter/material.dart';
import '../utils/color_performance.dart';
import '../utils/color_conversion.dart';

class ColorDebugOverlay extends StatefulWidget {
  final Color selectedColor;

  const ColorDebugOverlay({super.key, required this.selectedColor});

  @override
  _ColorDebugOverlayState createState() => _ColorDebugOverlayState();
}

class _ColorDebugOverlayState extends State<ColorDebugOverlay> {
  late ColorPerformance _performanceTracker;
  String _fpsCategory = "High";
  double _fps = 60.0;

  @override
  void initState() {
    super.initState();
    _performanceTracker = ColorPerformance();
    _performanceTracker.startTracking(onUpdated: () {
      setState(() {
        _fps = _performanceTracker.getFPS();
        _fpsCategory = _performanceTracker.getPerformanceCategory();
      });
    });
  }

  @override
  void dispose() {
    _performanceTracker.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FPS: ${_fps.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white)),
            Text('Performance: $_fpsCategory', style: const TextStyle(color: Colors.white)),
            Text('Color: ${ColorConversion.colorToHex(widget.selectedColor)}', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
