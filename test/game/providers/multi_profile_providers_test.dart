import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/core/services/settings/multi_profile_service.dart';
import 'package:synaptix/game/providers/multi_profile_providers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ProfileManagerState data class (no Hive needed)
  // ---------------------------------------------------------------------------

  group('ProfileManagerState data class', () {
    test('defaults: profiles empty, isLoading false, error null', () {
      const s = ProfileManagerState();
      expect(s.profiles, isEmpty);
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
      expect(s.activeProfile, isNull);
      expect(s.isInitialized, isFalse);
    });

    test('copyWith isLoading updated', () {
      const s = ProfileManagerState();
      expect(s.copyWith(isLoading: true).isLoading, isTrue);
    });

    test('copyWith isInitialized updated', () {
      const s = ProfileManagerState();
      expect(s.copyWith(isInitialized: true).isInitialized, isTrue);
    });

    test('copyWith error updated', () {
      const s = ProfileManagerState();
      expect(s.copyWith(error: 'oops').error, 'oops');
    });

    test('copyWith profiles updated', () {
      const s = ProfileManagerState();
      final p = ProfileData(
        id: 'p1',
        name: 'Alice',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
      );
      final updated = s.copyWith(profiles: [p]);
      expect(updated.profiles.length, 1);
      expect(updated.profiles.first.name, 'Alice');
    });

    test('copyWith preserves unchanged fields', () {
      final s = ProfileManagerState(
        isInitialized: true,
        profiles: [
          ProfileData(
              id: 'p1',
              name: 'Bob',
              createdAt: DateTime(2026),
              lastActive: DateTime(2026)),
        ],
      );
      final updated = s.copyWith(isLoading: true);
      expect(updated.isInitialized, isTrue);
      expect(updated.profiles.length, 1);
    });

    test('copyWith clearActiveProfile nulls activeProfile', () {
      final p = ProfileData(
        id: 'p1',
        name: 'Alice',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
      );
      final s = ProfileManagerState(activeProfile: p);
      final cleared = s.copyWith(clearActiveProfile: true);
      expect(cleared.activeProfile, isNull);
    });

    test('copyWith activeProfile updated', () {
      final p = ProfileData(
        id: 'p2',
        name: 'Carol',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
      );
      const s = ProfileManagerState();
      final updated = s.copyWith(activeProfile: p);
      expect(updated.activeProfile?.name, 'Carol');
    });
  });

  // ---------------------------------------------------------------------------
  // ProfileAwareXPNotifier (no Hive needed for setXP)
  // ---------------------------------------------------------------------------

  group('ProfileAwareXPNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state is 0', () {
      expect(container.read(profileAwareXPProvider), 0);
    });

    test('setXP sets state to given value', () {
      container.read(profileAwareXPProvider.notifier).setXP(100);
      expect(container.read(profileAwareXPProvider), 100);
    });

    test('setXP(0) sets state to 0', () {
      container.read(profileAwareXPProvider.notifier).setXP(500);
      container.read(profileAwareXPProvider.notifier).setXP(0);
      expect(container.read(profileAwareXPProvider), 0);
    });

    test('setXP can be called multiple times', () {
      container.read(profileAwareXPProvider.notifier).setXP(10);
      container.read(profileAwareXPProvider.notifier).setXP(20);
      container.read(profileAwareXPProvider.notifier).setXP(30);
      expect(container.read(profileAwareXPProvider), 30);
    });
  });

  // ---------------------------------------------------------------------------
  // ProfileManagerNotifier (Hive-backed)
  // ---------------------------------------------------------------------------

  group('ProfileManagerNotifier', () {
    late Directory tempDir;
    late MultiProfileService profileSvc;
    late ProviderContainer container;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('providers_notifier_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('multi_profiles');
      await Hive.openBox('settings');

      profileSvc = MultiProfileService();
      container = ProviderContainer(
        overrides: [
          multiProfileServiceProvider.overrideWithValue(profileSvc),
        ],
      );
      addTearDown(container.dispose);

      // Wait for ProfileManagerNotifier._initialize() to complete
      await Future.delayed(const Duration(milliseconds: 400));
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('isLoading is false after initialization', () {
      final state = container.read(profileManagerProvider);
      expect(state.isLoading, isFalse);
    });

    test('isInitialized is true after initialization', () {
      final state = container.read(profileManagerProvider);
      expect(state.isInitialized, isTrue);
    });

    test('profiles list is available after initialization', () {
      final state = container.read(profileManagerProvider);
      // _initialize migrates legacy profile → at least 1 profile
      expect(state.profiles, isA<List<ProfileData>>());
    });

    test('createProfile adds profile to state', () async {
      final initialCount =
          container.read(profileManagerProvider).profiles.length;
      await container
          .read(profileManagerProvider.notifier)
          .createProfile(name: 'NewUser');
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(profileManagerProvider);
      expect(state.profiles.length, greaterThan(initialCount));
    });

    test('createProfile: hasProfiles (profiles.isNotEmpty) is true', () async {
      await container
          .read(profileManagerProvider.notifier)
          .createProfile(name: 'CheckUser');
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(profileManagerProvider);
      expect(state.profiles.isNotEmpty, isTrue);
    });

    test('createProfile: isLoading false after operation', () async {
      await container
          .read(profileManagerProvider.notifier)
          .createProfile(name: 'IsLoadingCheck');
      await Future.delayed(const Duration(milliseconds: 200));

      expect(container.read(profileManagerProvider).isLoading, isFalse);
    });

    test('clearActiveProfile sets activeProfile to null', () async {
      await container
          .read(profileManagerProvider.notifier)
          .clearActiveProfile();
      final state = container.read(profileManagerProvider);
      expect(state.activeProfile, isNull);
    });

    test('clearActiveProfile also clears XP notifier to 0', () async {
      container.read(profileAwareXPProvider.notifier).setXP(999);
      await container
          .read(profileManagerProvider.notifier)
          .clearActiveProfile();
      expect(container.read(profileAwareXPProvider), 0);
    });

    test('refreshProfiles completes without error', () async {
      await expectLater(
        container.read(profileManagerProvider.notifier).refreshProfiles(),
        completes,
      );
    });

    test('refreshProfiles: isLoading false after completion', () async {
      await container.read(profileManagerProvider.notifier).refreshProfiles();
      expect(container.read(profileManagerProvider).isLoading, isFalse);
    });

    test('deleteProfile removes profile from state', () async {
      // Create 2 profiles so deletion is allowed
      final p = await container
          .read(profileManagerProvider.notifier)
          .createProfile(name: 'ToDelete');
      await Future.delayed(const Duration(milliseconds: 100));

      if (p != null) {
        final beforeCount =
            container.read(profileManagerProvider).profiles.length;
        await container
            .read(profileManagerProvider.notifier)
            .deleteProfile(p.id);
        await Future.delayed(const Duration(milliseconds: 100));

        final afterCount =
            container.read(profileManagerProvider).profiles.length;
        expect(afterCount, lessThan(beforeCount));
      }
    });

    test('deleteProfile returns false when only 1 profile left', () async {
      // Clear all, then create exactly 1 profile
      await profileSvc.clearAllProfiles();
      final p = await profileSvc.createProfile(name: 'OnlyOne');
      await container.read(profileManagerProvider.notifier).refreshProfiles();
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await container
          .read(profileManagerProvider.notifier)
          .deleteProfile(p!.id);
      expect(result, isFalse);
    });

    test('switchProfile updates activeProfile in state', () async {
      // Ensure there are at least 2 profiles
      final p = await container
          .read(profileManagerProvider.notifier)
          .createProfile(name: 'SwitchTarget');
      await Future.delayed(const Duration(milliseconds: 100));

      if (p != null) {
        await container
            .read(profileManagerProvider.notifier)
            .switchProfile(p.id);
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(profileManagerProvider);
        expect(state.isLoading, isFalse);
        expect(state.activeProfile?.id, p.id);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Convenience providers
  // ---------------------------------------------------------------------------

  group('convenience providers', () {
    late Directory tempDir;
    late ProviderContainer container;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('convenience_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('multi_profiles');
      await Hive.openBox('settings');

      final profileSvc = MultiProfileService();
      container = ProviderContainer(
        overrides: [
          multiProfileServiceProvider.overrideWithValue(profileSvc),
        ],
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 300));
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('isProfileLoadingProvider is false after init', () {
      expect(container.read(isProfileLoadingProvider), isFalse);
    });

    test('profileErrorProvider is null when no error', () {
      expect(container.read(profileErrorProvider), isNull);
    });

    test('availableProfilesProvider returns list', () {
      expect(
          container.read(availableProfilesProvider), isA<List<ProfileData>>());
    });

    test('currentProfileProvider reflects activeProfile from manager', () {
      final fromManager =
          container.read(profileManagerProvider).activeProfile?.id;
      final fromConvenience = container.read(currentProfileProvider)?.id;
      expect(fromConvenience, fromManager);
    });
  });
}
