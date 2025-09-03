import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../core/services/settings/audio_settings_service.dart';
import '../../core/services/settings/player_profile_service.dart';
import '../../core/services/settings/purchase_settings_service.dart';

/// DEPRECATED: AppSettings is now modularized into services/settings/*.
/// This controller now relies on AudioSettingsService, PlayerProfileService, and PurchaseSettingsService.
class SettingsController {
  static final _log = Logger('SettingsController');
  final AudioSettingsService audioService;
  final PlayerProfileService profileService;
  final PurchaseSettingsService purchaseService;

  /// Whether all audio is enabled (override music and sounds).
  ValueNotifier<bool> audioOn = ValueNotifier(true);

  /// Whether sound effect are enabled.
  ValueNotifier<bool> soundsOn = ValueNotifier(true);

  /// Whether music is enabled.
  ValueNotifier<bool> musicOn = ValueNotifier(true);

  /// The player's name.
  ValueNotifier<String> playerName = ValueNotifier('Player');

  /// List of purchased songs
  ValueNotifier<List<String>> purchasedSongs = ValueNotifier([]);

  /// Loads settings from persistent storage.
  SettingsController({
    required this.audioService,
    required this.profileService,
    required this.purchaseService,
  }) {
    _loadSettings();
  }

  /// Toggles the master audio setting.
  Future<void> toggleAudioOn() async {
    audioOn.value = !audioOn.value;
    await audioService.saveAudioOn(audioOn.value);
  }

  /// Toggles background music.
  Future<void> toggleMusicOn() async {
    musicOn.value = !musicOn.value;
    await audioService.saveMusicOn(musicOn.value);
  }

  /// Toggles sound effects.
  Future<void> toggleSoundsOn() async {
    soundsOn.value = !soundsOn.value;
    await audioService.saveSoundsOn(soundsOn.value);
  }

  /// Updates the player's name.
  Future<void> setPlayerName(String name) async {
    playerName.value = name;
    await profileService.savePlayerName(name);
  }

  /// Purchases a song and stores it persistently.
  Future<void> purchaseSong(String songFilename) async {
    List<String> purchased = await purchaseService.getPurchasedSongs();
    if (!purchased.contains(songFilename)) {
      purchased.add(songFilename);
      await purchaseService.savePurchasedSongs(purchased);
      purchasedSongs.value = purchased;
    }
  }

  /// Loads all settings from Hive.
  Future<void> _loadSettings() async {
    audioOn.value = audioService.getAudioOn(defaultValue: true);
    soundsOn.value = audioService.getSoundsOn(defaultValue: true);
    musicOn.value = audioService.getMusicOn(defaultValue: true);
    playerName.value = profileService.getPlayerName();
    purchasedSongs.value = await purchaseService.getPurchasedSongs();
    _log.fine(() => 'Loaded settings successfully.');
  }
}
