import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('onboarding_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  OnboardingSettingsService _make() => OnboardingSettingsService();

  // -------------------------------------------------------------------------
  // OnboardingProgress — pure data model
  // -------------------------------------------------------------------------

  group('OnboardingProgress.toMap / fromMap', () {
    test('round-trip preserves all scalar fields', () {
      const original = OnboardingProgress(
        completed: true,
        hasSeenIntro: true,
        hasCompletedProfile: false,
        currentStep: 5,
        username: 'alice',
        ageGroup: 'teens',
        country: 'US',
        intent: 'learn',
        playStyle: 'competitive',
        synaptixMode: 'focus',
        hasCompletedFirstChallenge: true,
        hasSeenRewardReveal: false,
      );
      final restored = OnboardingProgress.fromMap(original.toMap());
      expect(restored.completed, isTrue);
      expect(restored.hasSeenIntro, isTrue);
      expect(restored.hasCompletedProfile, isFalse);
      expect(restored.currentStep, 5);
      expect(restored.username, 'alice');
      expect(restored.ageGroup, 'teens');
      expect(restored.country, 'US');
      expect(restored.intent, 'learn');
      expect(restored.playStyle, 'competitive');
      expect(restored.synaptixMode, 'focus');
      expect(restored.hasCompletedFirstChallenge, isTrue);
      expect(restored.hasSeenRewardReveal, isFalse);
    });

    test('round-trip preserves categories list', () {
      const original = OnboardingProgress(
          categories: ['math', 'science', 'history']);
      final restored = OnboardingProgress.fromMap(original.toMap());
      expect(restored.categories, ['math', 'science', 'history']);
    });

    test('round-trip preserves lastUpdatedAt DateTime', () {
      final dt = DateTime(2026, 5, 1, 14, 30, 0);
      final original = OnboardingProgress(lastUpdatedAt: dt);
      final restored = OnboardingProgress.fromMap(original.toMap());
      expect(restored.lastUpdatedAt?.year, dt.year);
      expect(restored.lastUpdatedAt?.month, dt.month);
      expect(restored.lastUpdatedAt?.day, dt.day);
    });

    test('fromMap with empty map uses all defaults', () {
      final p = OnboardingProgress.fromMap({});
      expect(p.completed, isFalse);
      expect(p.currentStep, 0);
      expect(p.categories, isEmpty);
      expect(p.username, isNull);
    });

    test('copyWith updates only specified fields', () {
      const original = OnboardingProgress(currentStep: 2, username: 'bob');
      final updated =
          original.copyWith(currentStep: 7, hasSeenIntro: true);
      expect(updated.currentStep, 7);
      expect(updated.hasSeenIntro, isTrue);
      expect(updated.username, 'bob'); // unchanged
    });
  });

  // -------------------------------------------------------------------------
  // getOnboardingProgress / saveOnboardingProgress
  // -------------------------------------------------------------------------

  group('getOnboardingProgress', () {
    test('returns default progress when nothing stored', () async {
      final svc = _make();
      final progress = await svc.getOnboardingProgress();
      expect(progress.completed, isFalse);
      expect(progress.currentStep, 0);
    });

    test('returns saved progress after save', () async {
      final svc = _make();
      const toSave = OnboardingProgress(
        currentStep: 3,
        username: 'player1',
        hasSeenIntro: true,
      );
      await svc.saveOnboardingProgress(toSave);
      final retrieved = await svc.getOnboardingProgress();
      expect(retrieved.currentStep, 3);
      expect(retrieved.username, 'player1');
      expect(retrieved.hasSeenIntro, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Legacy key migration
  // -------------------------------------------------------------------------

  group('_migrateLegacyCompletionKey', () {
    test('migrates legacy "onboarding_complete"=true to new key', () async {
      final box = await Hive.openBox('settings');
      await box.put('onboarding_complete', true);

      final svc = _make();
      final progress = await svc.getOnboardingProgress();
      expect(progress.completed, isTrue);
      // legacy key should be removed
      expect(box.containsKey('onboarding_complete'), isFalse);
    });

    test('migrates legacy "onboarding_complete"=false without setting new key', () async {
      final box = await Hive.openBox('settings');
      await box.put('onboarding_complete', false);

      final svc = _make();
      await svc.getOnboardingProgress();
      expect(box.containsKey('onboarding_complete'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // setHasCompletedOnboarding
  // -------------------------------------------------------------------------

  group('setHasCompletedOnboarding', () {
    test('setting true marks all completion-related fields', () async {
      final svc = _make();
      await svc.setHasCompletedOnboarding(true);
      final progress = await svc.getOnboardingProgress();
      expect(progress.completed, isTrue);
      expect(progress.hasSeenIntro, isTrue);
      expect(progress.hasCompletedProfile, isTrue);
      expect(progress.currentStep, 10);
    });

    test('setting false does not reset hasSeenIntro if already true', () async {
      final svc = _make();
      await svc.setHasCompletedOnboarding(true);
      await svc.setHasCompletedOnboarding(false);
      final progress = await svc.getOnboardingProgress();
      expect(progress.completed, isFalse);
      expect(progress.hasSeenIntro, isTrue); // preserved
    });
  });

  // -------------------------------------------------------------------------
  // hasCompletedOnboarding
  // -------------------------------------------------------------------------

  group('hasCompletedOnboarding', () {
    test('returns false by default', () async {
      expect(await _make().hasCompletedOnboarding(), isFalse);
    });

    test('returns true after setHasCompletedOnboarding(true)', () async {
      final svc = _make();
      await svc.setHasCompletedOnboarding(true);
      expect(await svc.hasCompletedOnboarding(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // updateOnboardingProgress
  // -------------------------------------------------------------------------

  group('updateOnboardingProgress', () {
    test('partial update preserves existing fields', () async {
      final svc = _make();
      await svc.saveOnboardingProgress(
          const OnboardingProgress(username: 'charlie', currentStep: 2));
      await svc.updateOnboardingProgress(hasSeenIntro: true);
      final progress = await svc.getOnboardingProgress();
      expect(progress.username, 'charlie');
      expect(progress.currentStep, 2);
      expect(progress.hasSeenIntro, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // resetOnboardingProgress
  // -------------------------------------------------------------------------

  group('resetOnboardingProgress', () {
    test('resets all fields to defaults', () async {
      final svc = _make();
      await svc.setHasCompletedOnboarding(true);
      await svc.updateOnboardingProgress(username: 'reseeded');
      await svc.resetOnboardingProgress();
      final progress = await svc.getOnboardingProgress();
      expect(progress.completed, isFalse);
      expect(progress.username, isNull);
      expect(progress.currentStep, 0);
    });
  });
}
