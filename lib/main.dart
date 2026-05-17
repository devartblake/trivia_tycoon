import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/bootstrap/app_init.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'core/bootstrap/synaptix_app.dart';
import 'core/env.dart';
import 'game/providers/riverpod_providers.dart' hide themeNotifierProvider;
import 'synaptix/mode/synaptix_mode_notifier.dart';
import 'synaptix/mode/synaptix_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before doing anything else
  await EnvConfig.load();

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
  } catch (e) {
    LogManager.error('App initialization failed: $e', source: 'main');

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
