import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/screens/splash_variants/main_splash.dart';

/// AppAccessRouter determines the correct initial route for the user
/// after splash is complete, based on login + onboarding status.
class AppAccessRouter extends ConsumerWidget {
  const AppAccessRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginManager = ref.watch(loginManagerProvider);

    return FutureBuilder<String>(
      future: loginManager.getNextRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SimpleSplashScreen(onDone: () {});
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error determining access route')),
          );
        }

        final nextRoute = snapshot.data;
        if (nextRoute != null) {
          // Delay navigation until the next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              GoRouter.of(context).go(nextRoute);
            }
          });
        }

        return SimpleSplashScreen(onDone: () {});
      },
    );
  }
}
