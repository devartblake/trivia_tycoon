import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:trivia_tycoon/core/bootstrap/app_init.dart';
import 'package:trivia_tycoon/core/bootstrap/synaptix_app.dart';
import 'package:trivia_tycoon/core/env.dart';
import 'package:trivia_tycoon/core/env_sentry_extension.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/sentry_service.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart' hide themeNotifierProvider;
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_notifier.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_provider.dart';

/// Main entry point with Sentry error tracking integration
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before doing anything else
  await EnvConfig.load();

  // Initialize Sentry for error tracking
  await SentryService.initialize();

  // Run the app with Sentry's error handling wrapper
  await SentryFlutter.init(
    (options) {
      options.dsn = EnvConfig.sentryDsn;
      options.environment = EnvConfig.sentryEnvironment ?? 'development';
      options.tracesSampleRate = EnvConfig.sentryTraceSampleRate;
      options.maxBreadcrumbs = 200;
      options.captureFailedRequests = true;
    },
    appRunner: () => _runApp(),
  );
}

Future<void> _runApp() async {
  try {
    // Initialize services first
    final (manager, theme) = await AppInit.initialize();

    // Load auth state and user preferences before the first frame
    final isLoggedIn = await manager.authService.isLoggedIn();
    final savedAgeGroup =
        await manager.playerProfileService.getAgeGroup() ?? 'teens';
    final initialMode = SynaptixModeNotifier.mapAgeGroupToMode(savedAgeGroup);

    LogManager.info(
      'Session loaded: isLoggedIn=$isLoggedIn, ageGroup=$savedAgeGroup, synaptixMode=${initialMode.name}',
      source: 'main',
    );

    // Set user context in Sentry if logged in
    if (isLoggedIn) {
      final userProfile = await manager.playerProfileService.getUserProfile();
      if (userProfile != null) {
        SentryService.setUser(
          id: userProfile.userId ?? 'unknown',
          username: userProfile.playerName,
          email: userProfile.email,
          extras: {
            'age_group': savedAgeGroup,
            'synaptix_mode': initialMode.name,
          },
        );
      }
    }

    runApp(
      ProviderScope(
        overrides: [
          serviceManagerProvider.overrideWithValue(manager),
          isLoggedInSyncProvider.overrideWith((ref) => isLoggedIn),
          userAgeGroupProvider.overrideWith((ref) => savedAgeGroup),
          synaptixModeProvider.overrideWith((ref) {
            final notifier = SynaptixModeNotifier(manager.playerProfileService);
            notifier.deriveFromAgeGroup(savedAgeGroup);
            return notifier;
          }),
        ],
        child: SynaptixApp(initialData: (manager, theme)),
      ),
    );
  } catch (e, st) {
    LogManager.error('App initialization failed: $e', source: 'main', stackTrace: st);

    // Capture the initialization error in Sentry
    await SentryService.captureException(
      e,
      stackTrace: st,
      message: 'App initialization failed',
    );

    // Fallback - run app without pre-initialized state
    runApp(
      ProviderScope(
        child: const SynaptixApp(),
      ),
    );
  }
}

// SynaptixApp is defined in lib/core/bootstrap/synaptix_app.dart and shared
// across all platform entry points (main.dart, main_mobile.dart, main_web.dart).
