import 'package:flutter/material.dart';
import '../core/confetti_controller.dart';
import '../core/confetti_theme.dart';
import '../core/confetti_widget.dart';
import '../models/confetti_settings.dart';

class ConfettiPreview extends StatefulWidget {
  final ConfettiTheme theme;
  final ConfettiSettings settings;
  final ConfettiController controller;

  const ConfettiPreview({
    super.key,
    required this.theme,
    required this.settings,
    required this.controller,
  });

  @override
  State<ConfettiPreview> createState() => _ConfettiPreviewState();
}

class _ConfettiPreviewState extends State<ConfettiPreview>
    with TickerProviderStateMixin {
  late ConfettiController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startPreview();
  }

  void _startPreview() {
    _controller.updateTheme(widget.theme);
    _controller.start();
    setState(() => _isPlaying = true);
    _pulseController.repeat(reverse: true);
  }

  void _stopPreview() {
    _controller.stop();
    setState(() => _isPlaying = false);
    _pulseController.stop();
  }

  @override
  void didUpdateWidget(covariant ConfettiPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _startPreview();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            ConfettiWidget(
              controller: _controller,
              theme: widget.theme,
            ),
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isPlaying ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? "Live Preview" : "Tap to Preview",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isPlaying ? _stopPreview : _startPreview,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
