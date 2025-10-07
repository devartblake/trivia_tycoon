import 'package:flutter/material.dart';
import '../core/services/navigation/splash_type.dart';
import '../screens/splash_variants/fortune_wheel_splash.dart';
import '../screens/splash_variants/hq_terminal_splash.dart';
import '../screens/splash_variants/mind_market_splash.dart';
import '../screens/splash_variants/vault_splash.dart';

class SplashScreenPreview extends StatelessWidget {
  final SplashType type;

  const SplashScreenPreview({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    void defaultStartHandler() {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Splash animation completed'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2D2D2D),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Splash content
          _buildSplashContent(defaultStartHandler),

          // Info overlay (top)
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.preview,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getSplashName(type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashContent(VoidCallback onStart) {
    switch (type) {
      case SplashType.mindMarket:
        return MindMarketSplash(onStart: onStart);
      case SplashType.vaultUnlock:
        return VaultSplash(onStart: onStart);
      case SplashType.fortuneWheel:
        return FortuneWheelSplash(onStart: onStart);
      case SplashType.hqTerminal:
        return HqTerminalSplash(onStart: onStart);
      case SplashType.empireRising:
        return VaultSplash(onStart: onStart); // Placeholder
    }
  }

  String _getSplashName(SplashType type) {
    switch (type) {
      case SplashType.mindMarket:
        return 'Mind Market';
      case SplashType.vaultUnlock:
        return 'Vault Unlock';
      case SplashType.fortuneWheel:
        return 'Fortune Wheel';
      case SplashType.hqTerminal:
        return 'HQ Terminal';
      case SplashType.empireRising:
        return 'Empire Rising';
    }
  }
}
