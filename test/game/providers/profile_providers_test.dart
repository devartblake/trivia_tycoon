import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/game/providers/game_providers.dart';
import 'package:trivia_tycoon/game/providers/profile_providers.dart';
import 'package:trivia_tycoon/ui_components/login/providers/auth.dart';

void main() {
  late Directory tempDir;
  late PlayerProfileService profileService;
  late LocalAuthService authService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('profile_providers_test');
    Hive.init(tempDir.path);
    profileService = PlayerProfileService();
    authService = LocalAuthService(
      secureStorage: SecureStorage(),
      generalKey: GeneralKeyValueStorageService(),
      playerProfileService: profileService,
    );
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  ProviderContainer _makeContainer() {
    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        playerProfileServiceProvider.overrideWithValue(profileService),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // currentUserIdProvider — fallback chain
  // -------------------------------------------------------------------------

  group('currentUserIdProvider — fallback chain', () {
    test('returns stored userId when present', () async {
      await profileService.saveUserId('uid-abc');

      final container = _makeContainer();
      addTearDown(container.dispose);

      final userId = await container.read(currentUserIdProvider.future);
      expect(userId, 'uid-abc');
    });

    test('returns email prefix when no userId is stored', () async {
      // authService.login stores email in SecureStorage via the key 'user_email'
      await authService.login('alice@example.com');

      final container = _makeContainer();
      addTearDown(container.dispose);

      final userId = await container.read(currentUserIdProvider.future);
      expect(userId, 'alice'); // email.split('@').first
    });

    test('returns player name when no userId or email is stored', () async {
      await profileService.savePlayerName('QuizMaster');

      final container = _makeContainer();
      addTearDown(container.dispose);

      final userId = await container.read(currentUserIdProvider.future);
      expect(userId, 'QuizMaster');
    });

    test('returns "guest" when nothing meaningful is stored', () async {
      // No userId, no email, player name defaults to 'Player'
      final container = _makeContainer();
      addTearDown(container.dispose);

      final userId = await container.read(currentUserIdProvider.future);
      expect(userId, 'guest');
    });

    test('userId takes priority over email', () async {
      await profileService.saveUserId('stored-uid');
      await authService.login('other@example.com');

      final container = _makeContainer();
      addTearDown(container.dispose);

      final userId = await container.read(currentUserIdProvider.future);
      expect(userId, 'stored-uid');
    });

    test('email prefix takes priority over player name', () async {
      await authService.login('bob@test.com');
      await profileService.savePlayerName('BobCustomName');

      final container = _makeContainer();
      addTearDown(container.dispose);

      final userId = await container.read(currentUserIdProvider.future);
      expect(userId, 'bob');
    });
  });

  // -------------------------------------------------------------------------
  // playerProfileServiceProvider — basic operations
  // -------------------------------------------------------------------------

  group('PlayerProfileService — via provider', () {
    test('saveUserId persists value retrievable by getUserId', () async {
      await profileService.saveUserId('test-id-123');
      expect(await profileService.getUserId(), 'test-id-123');
    });

    test('getUserId returns null when not set', () async {
      expect(await profileService.getUserId(), isNull);
    });

    test('savePlayerName and getPlayerName round-trip', () async {
      await profileService.savePlayerName('SynaptiX');
      expect(await profileService.getPlayerName(), 'SynaptiX');
    });

    test('getPlayerName defaults to "Player" when not set', () async {
      expect(await profileService.getPlayerName(), 'Player');
    });
  });

  // -------------------------------------------------------------------------
  // LocalAuthService — email storage
  // -------------------------------------------------------------------------

  group('LocalAuthService — getStoredEmail', () {
    test('returns null before login', () async {
      final email = await authService.getStoredEmail();
      expect(email, isNull);
    });

    test('returns stored email after login', () async {
      await authService.login('charlie@domain.com');
      final email = await authService.getStoredEmail();
      expect(email, 'charlie@domain.com');
    });
  });
}
