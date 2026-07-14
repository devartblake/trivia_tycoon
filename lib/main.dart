import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:synaptix/core/bootstrap/app_init.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/services/sentry_service.dart';
import 'core/bootstrap/synaptix_app.dart';
import 'core/env.dart';
import 'game/providers/riverpod_providers.dart' hide themeNotifierProvider;
import 'synaptix/mode/synaptix_mode_notifier.dart';
import 'synaptix/mode/synaptix_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before doing anything else
  await EnvConfig.load();

  // Initialize Sentry when a DSN is configured (dart-define or env file).
  // Without a DSN the app runs exactly as before — no error tracking.
  final dsn = SentryService.getSentryDsn();

  if (dsn != null && dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = SentryService.getSentryEnvironment();
        options.tracesSampleRate = SentryService.getTraceSampleRate();
        options.maxBreadcrumbs = 200;
      },
      appRunner: _runApp,
    );
  } else {
    LogManager.info(
      'Sentry DSN not configured - error tracking disabled',
      source: 'main',
    );
    await _runApp();
  }
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

    SentryService.addBreadcrumb(
      message: 'App initialization completed',
      category: 'app-lifecycle',
      data: {
        'isLoggedIn': isLoggedIn.toString(),
        'ageGroup': savedAgeGroup,
        'mode': initialMode.name,
      },
    );

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
    LogManager.error('App initialization failed: $e',
        source: 'main', stackTrace: st);

    await SentryService.captureException(e, stackTrace: st);

    // Fallback - run app without pre-initialized state.
    // SynaptixApp re-attempts AppInit itself when initialData is null.
    runApp(
      ProviderScope(
        child: const SynaptixApp(),
      ),
    );
  }
}

// SynaptixApp is defined in lib/core/bootstrap/synaptix_app.dart and shared
// across all platform entry points (main.dart, main_mobile.dart, main_web.dart).
