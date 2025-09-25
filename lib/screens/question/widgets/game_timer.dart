import 'package:flutter/material.dart';

class EnhancedGameTimer extends StatefulWidget {
  final int duration;
  final VoidCallback onTimeUp;
  final bool isPaused;
  final String classLevel; // For age-appropriate timing

  const EnhancedGameTimer({
    super.key,
    required this.duration,
    required this.onTimeUp,
    this.isPaused = false,
    this.classLevel = '1',
  });

  @override
  State<EnhancedGameTimer> createState() => _EnhancedGameTimerState();
}

class _EnhancedGameTimerState extends State<EnhancedGameTimer>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late int remainingTime;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.duration;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      if (!widget.isPaused) {
        setState(() {
          remainingTime = (widget.duration * (1 - _progressController.value)).round();
        });

        // Start pulsing when time is running low
        if (remainingTime <= 10 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      }
    });

    if (!widget.isPaused) {
      _progressController.forward().whenComplete(() {
        if (remainingTime <= 0) {
          widget.onTimeUp();
        }
      });
    }
  }

  @override
  void didUpdateWidget(EnhancedGameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _progressController.stop();
        _pulseController.stop();
      } else {
        _progressController.forward();
        if (remainingTime <= 10) {
          _pulseController.repeat(reverse: true);
        }
      }
    }
  }

  Color _getTimerColor() {
    if (remainingTime <= 5) return Colors.red;
    if (remainingTime <= 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: remainingTime <= 10 ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getTimerColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress Ring
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: 1 - _progressController.value,
                    strokeWidth: 6,
                    color: _getTimerColor(),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),

                // Time Display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      remainingTime.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getTimerColor(),
                      ),
                    ),
                    Text(
                      'sec',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Pause Indicator
                if (widget.isPaused)
                  Positioned(
                    bottom: 8,
                    child: Icon(
                      Icons.pause_circle_filled,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
