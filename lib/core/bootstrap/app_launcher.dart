import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/analytics/app_lifecycle.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart'
    as providers;
import 'package:trivia_tycoon/screens/app_shell/app_shell.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_router.dart';

/// AppLauncher handles config + service initialization and launches the app
class AppLauncher extends ConsumerStatefulWidget {
  final (ServiceManager, ThemeNotifier) initialData;
  const AppLauncher({super.key, required this.initialData});

  @override
  ConsumerState<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends ConsumerState<AppLauncher> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initRouter();
  }

  Future<void> _initRouter() async {
    final router = await AppRouter.router();
    setState(() => _router = router);
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppLifecycleObserver(
      child: AppShell(router: _router!),
    );
  }
}
