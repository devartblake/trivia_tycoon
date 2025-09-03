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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Splash start triggered")),
      );
    }

    switch (type) {
      case SplashType.mindMarket:
        return MindMarketSplash(onStart: defaultStartHandler);
      case SplashType.vaultUnlock:
        return VaultSplash(onStart: defaultStartHandler);
      case SplashType.fortuneWheel:
        return FortuneWheelSplash(onStart: defaultStartHandler);
      case SplashType.hqTerminal:
        return HqTerminalSplash(onStart: defaultStartHandler);
      case SplashType.empireRising:
        return VaultSplash(onStart: defaultStartHandler); // Placeholder
    }
  }
}
