import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/bootstrap/app_init.dart';
import 'package:trivia_tycoon/core/bootstrap/app_launcher.dart';
import 'package:trivia_tycoon/core/widgets/offline_fallback_screen.dart';
import 'package:trivia_tycoon/screens/splash_variants/main_splash.dart';
import 'package:trivia_tycoon/widgets/app_logo.dart';

import 'core/manager/service_manager.dart';
import 'core/services/theme/theme_notifier.dart';
import 'game/providers/riverpod_providers.dart' hide themeNotifierProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (manager, theme) = await AppInit.initialize();
  runApp(ProviderScope(
      overrides: [
        serviceManagerProvider.overrideWithValue(manager),
        // themeNotifierProvider.overrideWithValue(theme),
      ],
      child: const TriviaTycoonApp()
    )
  );
}

class TriviaTycoonApp extends StatefulWidget {
  const TriviaTycoonApp({super.key});

  @override
  State<TriviaTycoonApp> createState() => _TriviaTycoonAppState();
}

class _TriviaTycoonAppState extends State<TriviaTycoonApp> {
  (ServiceManager, ThemeNotifier)? _initialData;
  bool _initialized = false;
  bool _splashFinished = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final data = await AppInit.initialize();
      setState(() {
        _initialData = data;
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e;
      });
    }
  }

  void _onSplashFinished() {
    setState(() {
      _splashFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return OfflineFallbackScreen(onRetry: _init);
    }

    if (!_splashFinished) {
      return SimpleSplashScreen(
        onDone: _onSplashFinished,
      );
    }

    if (!_initialized || _initialData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppLauncher(initialData: _initialData!);
  }
}
