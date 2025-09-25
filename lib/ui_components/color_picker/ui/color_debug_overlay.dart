import 'package:flutter/material.dart';
import '../utils/color_performance.dart';
import '../utils/color_conversion.dart';

class ColorDebugOverlay extends StatefulWidget {
  final Color selectedColor;

  const ColorDebugOverlay({super.key, required this.selectedColor});

  @override
  State<ColorDebugOverlay> createState() => _ColorDebugOverlayState();
}

class _ColorDebugOverlayState extends State<ColorDebugOverlay>
    with TickerProviderStateMixin {
  late ColorPerformance _performanceTracker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _fpsCategory = "High";
  double _fps = 60.0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _performanceTracker = ColorPerformance();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _performanceTracker.startTracking(onUpdated: () {
      if (mounted) {
        setState(() {
          _fps = _performanceTracker.getFPS();
          _fpsCategory = _performanceTracker.getPerformanceCategory();
        });

        // Pulse animation based on performance
        if (_fps < 30) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _performanceTracker.stopTracking();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getPerformanceColor() {
    if (_fps >= 55) return Colors.green;
    if (_fps >= 30) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon() {
    if (_fps >= 55) return Icons.speed_rounded;
    if (_fps >= 30) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(_isExpanded ? 16 : 12),
                constraints: BoxConstraints(
                  minWidth: 60,
                  maxWidth: _isExpanded ? 200 : 60,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(_isExpanded ? 16 : 12),
                  border: Border.all(
                    color: _getPerformanceColor().withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getPerformanceColor().withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getPerformanceIcon(),
          color: _getPerformanceColor(),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          '${_fps.toInt()}',
          style: TextStyle(
            color: _getPerformanceColor(),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    final hexColor = ColorConversion.colorToHex(widget.selectedColor);
    final rgbColor = "RGB(${widget.selectedColor.red},${widget.selectedColor.green},${widget.selectedColor.blue})";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.bug_report_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Debug',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Performance Section
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getPerformanceColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPerformanceColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPerformanceIcon(),
                    color: _getPerformanceColor(),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Performance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'FPS: ${_fps.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _getPerformanceColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Status: $_fpsCategory',
                style: TextStyle(
                  color: _getPerformanceColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Color Information Section
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Color Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hexColor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                rgbColor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Memory Usage (if available)
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.memory_rounded,
                    color: Colors.blue,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Memory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Widget: Active',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Tracker: Running',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
