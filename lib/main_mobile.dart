// Mobile entry point — Android / iOS
// flutter run -t lib/main_mobile.dart
// flutter build apk --target lib/main_mobile.dart
// flutter build ipa --target lib/main_mobile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/app_init.dart';
import 'core/bootstrap/synaptix_app.dart';
import 'core/env.dart';
import 'core/manager/log_manager.dart';
import 'game/providers/riverpod_providers.dart' hide themeNotifierProvider;
import 'synaptix/mode/synaptix_mode_notifier.dart';
import 'synaptix/mode/synaptix_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();

  try {
    final (manager, theme) = await AppInit.initialize();

    final isLoggedIn = await manager.authService.isLoggedIn();
    final savedAgeGroup =
        await manager.playerProfileService.getAgeGroup() ?? 'teens';
    final initialMode = SynaptixModeNotifier.mapAgeGroupToMode(savedAgeGroup);

    LogManager.info(
      'Mobile session: isLoggedIn=$isLoggedIn, ageGroup=$savedAgeGroup, mode=${initialMode.name}',
      source: 'main_mobile',
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
    LogManager.error('Mobile init failed: $e', source: 'main_mobile');
    runApp(const ProviderScope(child: SynaptixApp()));
  }
}
