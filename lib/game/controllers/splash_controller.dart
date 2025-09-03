import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/splash_settings_service.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_service.dart';
import '../../core/services/navigation/splash_type.dart';
import '../../ui_components/login/providers/auth.dart';

class SplashController {
  final OnboardingSettingsService onboardingService;
  final SplashSettingsService splashSettingsService;
  final AnalyticsService analyticsService;
  final AuthService authService;

  SplashController({
    required this.onboardingService,
    required this.splashSettingsService,
    required this.analyticsService,
    required this.authService,
  });

  /// Determines the appropriate route based on login and onboarding status.
  Future<String> initAppFlow() async {
    final isLoggedIn = await authService.isLoggedIn();
    final hasOnboarded = await onboardingService.getOnboardingStatus();

    final route = !isLoggedIn
        ? '/login'
        : !hasOnboarded
        ? '/onboarding'
        : '/';

    analyticsService.logEvent('init_app_flow', {
      'isLoggedIn': isLoggedIn,
      'hasOnboarded': hasOnboarded,
      'route': route,
    });

    return route;
  }

  /// Fetches the user's configured splash type.
  Future<SplashType> getUserSplashType() async {
    final type = await splashSettingsService.getSplashType();
    analyticsService.logEvent('splash_type_selected', {
      'splashType': type.name,
    });
    return type;
  }

  /// Legacy fallback if needed elsewhere
  Future<String> getInitialRoute() => initAppFlow();
}
