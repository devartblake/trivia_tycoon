import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/core/services/settings/audio_settings_service.dart';
import 'package:synaptix/core/services/settings/player_profile_service.dart';
import 'package:synaptix/core/services/settings/purchase_settings_service.dart';
import 'package:synaptix/game/controllers/settings_controller.dart';

void main() {
  late Directory tempDir;
  late AudioSettingsService audioService;
  late PlayerProfileService profileService;
  late PurchaseSettingsService purchaseService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_controller_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    audioService = await AudioSettingsService.initialize();
    profileService = PlayerProfileService();
    purchaseService = PurchaseSettingsService();
  });

  tearDown(() async {
    for (final boxName in ['settings', 'purchased_items', 'store_data']) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
        await Hive.box(boxName).close();
        await Hive.deleteBoxFromDisk(boxName);
      }
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  SettingsController makeController() => SettingsController(
        audioService: audioService,
        profileService: profileService,
        purchaseService: purchaseService,
      );

  // ---------------------------------------------------------------------------
  // Construction / load
  // ---------------------------------------------------------------------------

  test('initial ValueNotifier values reflect Hive defaults', () {
    final controller = makeController();
    expect(controller.audioOn.value, isTrue);
    expect(controller.musicOn.value, isTrue);
    expect(controller.soundsOn.value, isTrue);
    expect(controller.playerName.value, 'Player');
    expect(controller.purchasedSongs.value, isEmpty);
  });

  // ---------------------------------------------------------------------------
  // toggleAudioOn
  // ---------------------------------------------------------------------------

  test('toggleAudioOn flips audioOn.value and persists', () async {
    final controller = makeController();
    expect(controller.audioOn.value, isTrue);

    await controller.toggleAudioOn();
    expect(controller.audioOn.value, isFalse);
    expect(audioService.getAudioOn(), isFalse);

    await controller.toggleAudioOn();
    expect(controller.audioOn.value, isTrue);
    expect(audioService.getAudioOn(), isTrue);
  });

  // ---------------------------------------------------------------------------
  // toggleMusicOn
  // ---------------------------------------------------------------------------

  test('toggleMusicOn flips musicOn.value and persists', () async {
    final controller = makeController();
    await controller.toggleMusicOn();
    expect(controller.musicOn.value, isFalse);
    expect(audioService.getMusicOn(), isFalse);
  });

  // ---------------------------------------------------------------------------
  // toggleSoundsOn
  // ---------------------------------------------------------------------------

  test('toggleSoundsOn flips soundsOn.value and persists', () async {
    final controller = makeController();
    await controller.toggleSoundsOn();
    expect(controller.soundsOn.value, isFalse);
    expect(audioService.getSoundsOn(), isFalse);
  });

  // ---------------------------------------------------------------------------
  // setPlayerName
  // ---------------------------------------------------------------------------

  test('setPlayerName updates playerName.value and persists', () async {
    final controller = makeController();
    await controller.setPlayerName('Frank');
    expect(controller.playerName.value, 'Frank');
    expect(await profileService.getPlayerName(), 'Frank');
  });

  // ---------------------------------------------------------------------------
  // purchaseSong
  // ---------------------------------------------------------------------------

  test('purchaseSong adds song to purchasedSongs list', () async {
    final controller = makeController();
    await controller.purchaseSong('rock_anthem.mp3');
    expect(controller.purchasedSongs.value, contains('rock_anthem.mp3'));
  });

  test('purchaseSong is idempotent — duplicate not added', () async {
    final controller = makeController();
    await controller.purchaseSong('rock_anthem.mp3');
    await controller.purchaseSong('rock_anthem.mp3');
    expect(
      controller.purchasedSongs.value
          .where((s) => s == 'rock_anthem.mp3')
          .length,
      1,
    );
  });

  test('purchaseSong adds multiple distinct songs', () async {
    final controller = makeController();
    await controller.purchaseSong('track_a.mp3');
    await controller.purchaseSong('track_b.mp3');
    expect(controller.purchasedSongs.value,
        containsAll(['track_a.mp3', 'track_b.mp3']));
  });
}
