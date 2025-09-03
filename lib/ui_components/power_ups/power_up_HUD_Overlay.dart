import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/power_up_timer_provider.dart';
import 'package:trivia_tycoon/game/models/power_up.dart';

import '../../game/providers/riverpod_providers.dart';

class PowerUpHUDOverlay extends ConsumerStatefulWidget {
  const PowerUpHUDOverlay({super.key});

  @override
  ConsumerState<PowerUpHUDOverlay> createState() => _PowerUpHUDOverlayState();
}

class _PowerUpHUDOverlayState extends ConsumerState<PowerUpHUDOverlay> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  PowerUp? _previousPowerUp;
  bool _flashed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleAnimation(PowerUp? current) {
    final isEnding = current == null && _previousPowerUp != null;

    if (current != null && _previousPowerUp == null) {
      _controller.forward(); // Show
      _flashed = false; // Reset flash flag
    } else if (isEnding && !_flashed && current == null && _previousPowerUp != null) {
      _triggerFlashEffect(); // Flash before hiding
      _controller.reverse(); // Hide
      _flashed = true;
    }
    _previousPowerUp = current;
  }

  void _triggerFlashEffect() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
        // Optional: Shake animation of color pulse can go here.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePowerUp = ref.watch(equippedPowerUpProvider);
    final remainingSeconds = ref.watch(powerUpTimeProvider);

    _handleAnimation(activePowerUp);

    if (activePowerUp == null || remainingSeconds == null || remainingSeconds <= 0) {
      return const SizedBox.shrink();
    }

    final totalDuration = activePowerUp.duration;
    final progress = remainingSeconds / totalDuration;

    final glow = 4 + (_glowController.value * 6);
    final glowColor = _getGlowColor(activePowerUp.type);

    return Positioned(
      top: 60,
      right: 12,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withOpacity(0.8),
                              blurRadius: glow,
                              spreadRadius: glow / 2,
                            )
                          ],
                        ),
                        child: Image.asset(activePowerUp.iconPath, height: 24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${activePowerUp.name} - ${remainingSeconds ~/ 60}m ${remainingSeconds % 60}s",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(glowColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Optional helper for color based on power-up type
  Color _getGlowColor(String type) {
    switch (type.toLowerCase()) {
      case 'hint':
        return Colors.purpleAccent;
      case 'eliminate':
        return Colors.redAccent;
      case 'xp':
        return Colors.blueAccent;
      case 'boost':
        return Colors.greenAccent;
      case 'shield':
        return Colors.cyanAccent;
      default:
        return Colors.amberAccent;
    }
  }
}
