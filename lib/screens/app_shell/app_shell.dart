import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/utils/theme_mapper.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart' as providers;
import 'package:trivia_tycoon/ui_components/power_ups/power_up_HUD_Overlay.dart';
import '../../core/theme/app_scroll_behavior.dart';

/// AppShell is the main scaffold wrapper for the app
class AppShell extends ConsumerWidget {
  final GoRouter router;

  const AppShell({super.key, required this.router});

  /// Optionally, expose static app metadata if needed globally
  static String? get pkg => ConfigService.getPackage("trivia_tycoon");
  static String? get bundle => ConfigService.getBundle("trivia_tycoon");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageGroup = ref.watch(providers.userAgeGroupProvider);
    final themeSettings = ref.watch(providers.themeSettingsProvider);

    final primaryColor = themeSettings.primaryColor;
    final brightness = themeSettings.brightness;

    final appTheme = ThemeMapper.getThemeForAgeGroup(ageGroup);

    return MaterialApp.router(
      key: ValueKey("${primaryColor.value}-${brightness.name}"),
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      title: 'Trivia Tycoon',
      theme: ThemeData(
        brightness: brightness,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Stack(
          children: [
            if (child != null) child,
            const PowerUpHUDOverlay(),
          ],
        ),
      ),
    );
  }
}
