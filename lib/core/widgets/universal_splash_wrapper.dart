import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/navigation/splash_type.dart';
import 'package:trivia_tycoon/screens/splash_variants/fortune_wheel_splash.dart';
import 'package:trivia_tycoon/screens/splash_variants/hq_terminal_splash.dart';
import 'package:trivia_tycoon/screens/splash_variants/mind_market_splash.dart';
import 'package:trivia_tycoon/screens/splash_variants/vault_splash.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

final splashTypeProvider = FutureProvider<SplashType>((ref) {
  final splashSettingsService = ref.watch(serviceManagerProvider).splashSettingsService;
  return splashSettingsService.getSplashType();
});
/// UniversalSplashWrapper wraps your app's startup experience
/// and shows the selected splash animation based on user or default setting.
class UniversalSplashWrapper extends ConsumerWidget {
  final VoidCallback onSplashFinished;

  const UniversalSplashWrapper({super.key, required this.onSplashFinished});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashTypeAsyncValue = ref.watch(splashTypeProvider);

    return splashTypeAsyncValue.when(
      data: (splashType) {
        final type = splashType ?? SplashType.mindMarket; // Handle potential null from provider if needed
        switch (type) {
          case SplashType.fortuneWheel:
            return FortuneWheelSplash(onStart: onSplashFinished);
          case SplashType.mindMarket:
            return MindMarketSplash(onStart: onSplashFinished);
          case SplashType.vaultUnlock:
            return VaultSplash(onStart: onSplashFinished);
          case SplashType.hqTerminal:
            return HqTerminalSplash(onStart: onSplashFinished);
          case SplashType.empireRising:
            return VaultSplash(onStart: onSplashFinished); // Placeholder
        }
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      ),
      error: (error, stackTrace) {
        // Log the error
        print("Error loading splash type from provider: $error");
        // Show a fallback splash or an error message
        return MindMarketSplash(onStart: onSplashFinished);
        // Or an error widget
        // return Scaffold(
        //   body: Center(child: Text('Error loading splash: $error')),
        // );
      },
    );
  }
}
