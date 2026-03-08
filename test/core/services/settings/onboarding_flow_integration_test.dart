import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/navigation/navigation_redirect_service.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/game/providers/onboarding_providers.dart';

void main() {
  group('Onboarding flow integration scenarios', () {
    late Directory tempDir;
    late OnboardingSettingsService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('onboarding_flow_test_');
      Hive.init(tempDir.path);
      service = OnboardingSettingsService();
      await service.resetOnboardingProgress();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('complete flow persists finished onboarding payload', () async {
      await service.updateOnboardingProgress(
        completed: true,
        hasSeenIntro: true,
        hasCompletedProfile: true,
        currentStep: 5,
        username: 'TriviaChamp_42',
        ageGroup: '18_24',
        country: 'United States',
        categories: const ['science', 'history'],
      );

      final progress = await service.getOnboardingProgress();

      expect(progress.completed, true);
      expect(progress.hasSeenIntro, true);
      expect(progress.hasCompletedProfile, true);
      expect(progress.currentStep, 5);
      expect(progress.username, 'TriviaChamp_42');
      expect(progress.categories, ['science', 'history']);
    });

    test('skip flow keeps onboarding incomplete and redirects to onboarding', () async {
      await service.updateOnboardingProgress(
        completed: false,
        hasSeenIntro: true,
        hasCompletedProfile: false,
        currentStep: 3,
        username: 'PartialUser',
      );

      final progress = await service.getOnboardingProgress();
      expect(progress.completed, false);
      expect(progress.currentStep, 3);

      final redirect = NavigationRedirectService.resolveOnboardingRedirect(
        currentPath: '/home',
        isLoggedIn: true,
        phase: OnboardingPhase.profileSetup,
      );
      expect(redirect, '/onboarding');
    });

    test('relaunch-resume flow restores last incomplete step', () async {
      await service.updateOnboardingProgress(
        completed: false,
        hasSeenIntro: true,
        hasCompletedProfile: false,
        currentStep: 4,
        username: 'ResumeUser',
        ageGroup: '25_34',
      );

      final reloadedService = OnboardingSettingsService();
      final resumed = await reloadedService.getOnboardingProgress();

      expect(resumed.completed, false);
      expect(resumed.currentStep, 4);
      expect(resumed.username, 'ResumeUser');
      expect(resumed.ageGroup, '25_34');
    });

    test('post-completion app entry allows normal routes', () async {
      await service.updateOnboardingProgress(
        completed: true,
        hasSeenIntro: true,
        hasCompletedProfile: true,
        currentStep: 5,
      );

      final redirect = NavigationRedirectService.resolveOnboardingRedirect(
        currentPath: '/home',
        isLoggedIn: true,
        phase: OnboardingPhase.done,
      );

      expect(redirect, isNull);
    });
  });
}
