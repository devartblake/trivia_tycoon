import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/navigation/splash_type.dart';
import 'package:trivia_tycoon/core/services/storage/config_storage_service.dart';
import '../../../game/controllers/theme_settings_controller.dart';
import '../../../ui_components/spin_wheel/models/spin_system_models.dart';

class AppSettings {
  final ConfigStorageService _config;

  AppSettings(this._config);

  static const _boxName = 'settings';
  static const String _qrAutoLaunchKey = 'qr_auto_launch';
  static const String _qrScanLimitKey = 'qr_scan_limit';
  static const String _splashTypeKey = 'splash_type';

  static Future<AppSettings> initialize(ConfigStorageService config) async {
    return AppSettings(config);
  }

  /// Sets the splash screen type based on the selected enum value.
  ///
  /// Example usage:
  /// ```dart
  /// await AppSettings.setSplashType(SplashType.vaultUnlock);
  /// ```
  static Future<void> setSplashType(SplashType type) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_splashTypeKey, type.name);
  }

  /// Retrieves the splash screen type from Hive storage.
  ///
  /// Returns the stored [SplashType], or defaults to [SplashType.vaultUnlock]
  /// if not set or unrecognized.
  static Future<SplashType> getSplashType() async {
    final box = await Hive.openBox(_boxName);
    final name = box.get(_splashTypeKey);
    return SplashType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SplashType.fortuneWheel,
    );
  }

  /// Enable or disable auto-launch for scanned URLs.
  static Future<void> setQrAutoLaunchEnabled(bool enabled) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_qrAutoLaunchKey, enabled);
  }

  /// Retrieve auto-launch setting.
  static Future<bool> getQrAutoLaunchEnabled({bool defaultValue = true}) async {
    final box = await Hive.openBox(_boxName);
    return box.get(_qrAutoLaunchKey, defaultValue: defaultValue);
  }

  /// Set the maximum number of QR scans to keep in history.
  static Future<void> setQrScanHistoryLimit(int limit) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_qrScanLimitKey, limit);
  }

  /// Get the max number of QR scans to keep in history.
  static Future<int> getQrScanHistoryLimit({int defaultValue = 50}) async {
    final box = await Hive.openBox(_boxName);
    return box.get(_qrScanLimitKey, defaultValue: defaultValue);
  }

  /// Saves whether audio is enabled.
  static Future<void> saveAudioOn(bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put('audioOn', value);
  }

  /// Retrieves the audio setting.
  static Future<bool> getAudioOn({required bool defaultValue}) async {
    final box = await Hive.openBox(_boxName);
    return box.get('audioOn', defaultValue: defaultValue);
  }

  /// Saves whether music is enabled.
  static Future<void> saveMusicOn(bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put('musicOn', value);
  }
  /// Retrieves the music setting.
  static Future<bool> getMusicOn({required bool defaultValue}) async {
    final box = await Hive.openBox(_boxName);
    return box.get('musicOn', defaultValue: defaultValue);
  }

  /// Saves whether sound effects are enabled.
  static Future<void> saveSoundsOn(bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put('soundsOn', value);
  }

  /// Retrieves the sound effects setting.
  static Future<bool> getSoundsOn({required bool defaultValue}) async {
    final box = await Hive.openBox(_boxName);
    return box.get('soundsOn', defaultValue: defaultValue);
  }

  /// Saves brightness setting (light/dark).
  static Future<void> setBrightness(Brightness brightness) async {
    final box = await Hive.openBox(_boxName);
    await box.put('brightness', brightness.name);
  }

  /// Retrieves brightness setting.
  static Future<Brightness> getBrightness() async {
    final box = await Hive.openBox(_boxName);
    final name = box.get('brightness', defaultValue: 'light');
    return name == 'dark' ? Brightness.dark : Brightness.light;
  }

  /// ** Saves the enable/disable  Admin mode
  static Future<void> setAdminMode(bool enabled) async {
    final box = await Hive.openBox('settings');
    await box.put(_boxName, enabled);
  }

  /// ** Retrieve Admin mode
  static Future<bool> isAdminMode() async {
    final box = await Hive.openBox('settings');
    return box.get(_boxName, defaultValue: false);
  }

  /// Retrieve Admin user role
  static Future<bool> isAdminUser() async {
    final role = await getString('userRole');
    return role == 'admin';
  }

  /// Saves the player's name.
  static Future<void> savePlayerName(String name) async {
    final box = await Hive.openBox(_boxName);
    await box.put('playerName', name);
  }

  /// Retrieves the player's name.
  static Future<String> getPlayerName() async {
    final box = await Hive.openBox(_boxName);
    return box.get('playerName', defaultValue: 'Player');
  }

  /// Saves player progress.
  static Future<void> savePlayerProgress(Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_boxName);
    await box.put('playerProgress', progress);
  }

  /// Retrieves player progress.
  static Future<Map<String, dynamic>> getPlayerProgress() async {
    final box = await Hive.openBox(_boxName);
    return Map<String, dynamic>.from(box.get('playerProgress', defaultValue: {}));
  }

  static Future<void> setHasCompletedOnboarding(bool value) async {
    await setBool(_boxName, value);
  }

  static Future<bool> hasCompletedOnboarding() async {
    final value = await getBool(_boxName);
    return value is bool ? value : false;
  }

  /// Saves quiz progress.
  static Future<void> saveQuizProgress(Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_boxName);
    await box.put('quizProgress', progress);
  }

  /// Retrieves quiz progress.
  static Future<Map<String, dynamic>> getQuizProgress() async {
    final box = await Hive.openBox(_boxName);
    return Map<String, dynamic>.from(box.get('quizProgress', defaultValue: {}));
  }

  /// Saves unlocked achievements.
  static Future<void> saveUnlockedAchievements(List<String> achievements) async {
    final box = await Hive.openBox(_boxName);
    await box.put('unlockedAchievements', achievements);
  }

  /// Retrieves unlocked achievements.
  static Future<List<String>> getUnlockedAchievements() async {
    final box = await Hive.openBox(_boxName);
    return List<String>.from(box.get('unlockedAchievements', defaultValue: []));
  }

  /// A helper function for purchasing a song: retrieves the current list, adds if not present, and saves it.
  static Future<void> purchaseSong(String songFilename) async {
    final box = await Hive.openBox(_boxName);
    List<String> purchased = List<String>.from(box.get('purchasedSongs', defaultValue: []));
    if (!purchased.contains(songFilename)) {
      purchased.add(songFilename);
      await box.put('purchasedSongs', purchased);
    }
  }

  /// Saves purchased songs.
  static Future<void> savePurchasedSongs(List<String> songs) async {
    final box = await Hive.openBox(_boxName);
    await box.put('purchasedSongs', songs);
  }

  /// Retrieves purchased songs.
  static Future<List<String>> getPurchasedSongs() async {
    final box = await Hive.openBox(_boxName);
    return List<String>.from(box.get('purchasedSongs', defaultValue: []));
  }

  /// Retrieves the onboarding completion status.
  static Future<bool> getOnboardingStatus() async {
    final box = await Hive.openBox(_boxName);
    return box.get('onboarding_completed', defaultValue: false);
  }

  /// Marks onboarding as completed.
  static Future<void> setOnboardingCompleted() async {
    final box = await Hive.openBox(_boxName);
    await box.put('onboarding_completed', true);
  }

  /// ** Retrieve drawer theme **
  static Future<List<String>?> getDrawerTheme() async =>
      await AppSettings.getStringList(_boxName);

  /// ** Save drawer theme **
  static Future<void> setDrawerTheme(String theme) async =>
      await AppSettings.setStringList(_boxName, theme as List<String>);

  /// Saves the selected theme name.
  static Future<void> setThemeName(String name) async {
    final box = await Hive.openBox(_boxName);
    await box.put('theme_name', name);
  }

  /// Retrieves the selected theme name.
  static Future<String> getThemeName() async {
    final box = await Hive.openBox(_boxName);
    return box.get('theme_name', defaultValue: 'Default');
  }

  /// Saves the primary color as an integer.
  static Future<void> setPrimaryColor(Color color) async {
    final box = await Hive.openBox(_boxName);
    await box.put('primary_color', color.value);
  }

  /// Retrieves the primary color.
  static Future<Color> getPrimaryColor() async {
    final box = await Hive.openBox(_boxName);
    final value = box.get('primary_color');
    return value is int ? Color(value) : const Color(0xFF2196F3); // Default to blue
  }
  /// ** Saves the custom theme presets
  static Future<void> saveCustomThemePreset(Map<String, dynamic> preset) async {
    final box = await Hive.openBox(_boxName);
    final List<dynamic> existing = box.get(_boxName, defaultValue: []);
    existing.add(preset);
    await box.put(_boxName, existing);
  }

  /// ** Retrieves the custom theme presets.
  static Future<List<Map<String, dynamic>>> getCustomThemePresets() async {
    final box = await Hive.openBox(_boxName);
    final List<dynamic> presets = box.get(_boxName, defaultValue: []);
    return presets.cast<Map<String, dynamic>>();
  }

  /// Save a named theme preset
  static Future<void> saveThemePreset(ThemeSettings preset) async {
    final box = await Hive.openBox('theme_presets');
    await box.put(preset.themeName, {
      'name': preset.themeName,
      'primaryColor': preset.primaryColor.value,
      'secondaryColor': preset.secondaryColor.value,
      'brightness': preset.brightness == Brightness.dark ? 'dark' : 'light',
    });
  }

  /// Load all custom theme presets
  static Future<List<ThemeSettings>> getAllThemePresets() async {
    final box = await Hive.openBox('theme_presets');
    return box.values.map((e) {
      return ThemeSettings(
        themeName: e['name'],
        primaryColor: Color(e['primaryColor']),
        secondaryColor: Color(e['secondaryColor']),
        brightness: e['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      );
    }).toList();
  }

  /// Delete a custom preset by name
  static Future<void> deleteThemePreset(String name) async {
    final box = await Hive.openBox('theme_presets');
    await box.delete(name);
  }

  /// Save a new or edited custom theme
  static Future<void> saveCustomTheme(ThemeSettings theme) async {
    final box = await Hive.openBox(_boxName);
    final current = await getCustomThemes();
    final updated = [
      ...current.where((t) => t.themeName != theme.themeName),
      theme,
    ];
    final encoded = updated.map((t) => {
      'name': t.themeName,
      'primary': t.primaryColor.value,
      'secondary': t.secondaryColor.value,
      'brightness': t.brightness == Brightness.dark ? 'dark' : 'light',
    }).toList();
    await box.put(_boxName, encoded);
  }

  /// Delete a saved custom theme
  static Future<void> deleteCustomTheme(String name) async {
    final box = await Hive.openBox(_boxName);
    final current = await getCustomThemes();
    final updated = current.where((t) => t.themeName != name).toList();
    final encoded = updated.map((t) => {
      'name': t.themeName,
      'primary': t.primaryColor.value,
      'secondary': t.secondaryColor.value,
      'brightness': t.brightness == Brightness.dark ? 'dark' : 'light',
    }).toList();
    await box.put(_boxName, encoded);
  }

  /// Get all saved custom themes
  static Future<List<ThemeSettings>> getCustomThemes() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_boxName, defaultValue: []);
    if (raw is List) {
      return raw.map((entry) {
        return ThemeSettings(
          themeName: entry['name'],
          primaryColor: Color(entry['primary']),
          secondaryColor: Color(entry['secondary']),
          brightness: entry['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
        );
      }).toList();
    }
    return [];
  }

  /// Saves confetti settings.
  static Future<void> saveConfettiSettings(Map<String, dynamic> settings) async {
    final box = await Hive.openBox(_boxName);
    await box.put("confettiSettings", settings);
  }

  /// Retrieves confetti settings.
  static Future<Map<String, dynamic>> getConfettiSettings() async {
    final box = await Hive.openBox(_boxName);
    return Map<String, dynamic>.from(box.get('confettiSettings', defaultValue: {}));
  }

  /// Saves the selected confetti theme.
  static Future<void> saveConfettiTheme(String theme) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiTheme', theme);
  }

  /// Retrieve the selected confetti theme.
  static Future<String> getConfettiTheme() async {
    final box = await Hive.openBox(_boxName);
    return box.get('confettiTheme', defaultValue: 'default');
  }

  /// Saves confetti animation speed.
  static Future<void> saveConfettiSpeed(double speed) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiSpeed', speed);
  }

  /// Retrieves confetti animation speed.
  static Future<double> getConfettiSpeed() async {
    final box = await Hive.openBox(_boxName);
    return box.get('confettiSpeed', defaultValue: 1.0);
  }

  /// Saves the number of confetti particles.
  static Future<void> saveConfettiParticleCount(int count) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiParticleCount', count);
  }

  /// Retrieves the number of confetti particles.
  static Future<int> getConfettiParticleCount() async {
    final box = await Hive.openBox(_boxName);
    return box.get('confettiParticleCount', defaultValue: 100);
  }

  /// Saves confetti custom colors.
  static Future<void> saveConfettiColors(List<int> colors) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiColors', colors);
  }

  /// Retrieves confetti custom colors.
  static Future<List<int>> getConfettiColors() async {
    final box = await Hive.openBox(_boxName);
    return List<int>.from(box.get('confettiColors', defaultValue: []));
  }

  /// Saves the selected confetti preset.
  static Future<void> saveConfettiPreset(String preset) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiPreset', preset);
  }

  /// Retrieves the selected confetti preset.
  static Future<String> getConfettiPreset() async {
    final box = await Hive.openBox(_boxName);
    return box.get('confettiPreset', defaultValue: 'default');
  }

  /// Saves the particle density preferences (Auto, Low, Medium, High)
  static Future<void> saveParticleDensity(String density) async {
    final box = await Hive.openBox(_boxName);
    await box.put('particleDensity', density);
  }

  /// Retrieves the particle density setting (defaults to "Auto")
  static Future<String> getParticleDensity() async {
    final box = await Hive.openBox(_boxName);
    return box.get('particleDensity', defaultValue: 'Auto');
  }

  /// ** Set the DepthCard 3D theme**
  static Future<void> setDepthCardTheme(String themeName) async {
    final box = await Hive.openBox(_boxName);
    await box.put('depthCardTheme', themeName);
  }

  /// **Get the DepthCard 3D theme**
  static Future<String?> getDepthCardTheme() async {
    final box = await Hive.openBox(_boxName);
    return box.get('depthCardTheme', defaultValue: 'light');
  }

  /// Gets a DateTime from a stored ISO8601 string
  static Future<DateTime?> getDateTime(String key) async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(key);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Sets a DateTime as an ISO8601 string
  static Future<void> setDateTime(String key, DateTime value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value.toIso8601String());
  }

  /// Gets an integer value from Hive
  static Future<int> getInt(String key) async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(key);
    return value is int ? value : 0;
  }

  /// Sets an integer value to Hive
  static Future<void> setInt(String key, int value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  /// Retrieves a Color value stored as int
  static Future<Color?> getColor(String key) async {
    final box = await Hive.openBox('settings');
    final colorValue = box.get(key);
    return colorValue is int ? Color(colorValue) : null;
  }

  /// Saves a Color value as int
  static Future<void> setColor(String key, Color color) async {
    final box = await Hive.openBox('settings');
    await box.put(key, color.value);
  }

  /// Retrieves a bool value
  static Future<bool?> getBool(String key) async {
    final box = await Hive.openBox('prefs');
    final value = box.get(key);
    return value is bool ? value : null;
  }

  /// Sets a bool value
  static Future<void> setBool(String key, bool value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  /// Saves theme.
  static Future<void> setString(String key, String value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  /// Retrieves theme.
  static Future<String?> getString(String key) async {
    final box = await Hive.openBox(_boxName);
    return box.get(key) as String?;
  }

  /// Save a List<String> as a single comma-separated string
  static Future<void> setStringList(String key, List<String> values) async {
    final box = await Hive.openBox('preferences');
    await box.put(key, values.join(','));
  }

  /// Retrieve a List<String> by splitting a comma-separated string
  static Future<List<String>?> getStringList(String key) async {
    final box = await Hive.openBox('preferences');
    final stored = box.get(key);
    if (stored is String && stored.isNotEmpty) {
      return stored.split(',');
    }
    return null;
  }

  /// Remove theme.
  static Future<void> remove(String key) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(key);
  }

  /// Admin mode
  static Future<void> setAdminUser(bool value) => setBool('is_admin', value);

  /// Example: onboarding flag
  static Future<void> setOnboardingComplete(bool value) =>
      setBool('onboarding_complete', value);

  /// Saves the last jackpot win timestamp
  static Future<void> setJackpotTime(DateTime time) async {
    final box = await Hive.openBox(_boxName);
    await box.put('lastJackpotWin', time.toIso8601String());
  }

  /// Retrieves the last jackpot win timestamp
  static Future<DateTime> getJackpotTime() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('lastJackpotWin');
    return raw != null
        ? DateTime.parse(raw)
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Saves the current win streak
  static Future<void> setWinStreak(int streak) async {
    final box = await Hive.openBox(_boxName);
    await box.put('winStreak', streak);
  }

  /// ** Retrieve win streak **
  static Future<int> getWinStreak() async {
    final box = await Hive.openBox('settingsBox');
    return box.get('winStreak', defaultValue: 0);
  }

  /// *** Retrieve exclusive based on currency **
  static Future<int> getExclusiveCurrency() async =>
      await getInt("exclusiveCurrency") ?? 0;

  /// ** Retrieve total spins
  static Future<int> getTotalSpins() async {
    final box = await Hive.openBox(_boxName);
    return box.get('totalSpins', defaultValue: 0);
  }

  /// ** Increment total spins
  static Future<void> incrementTotalSpins() async {
    final box = await Hive.openBox(_boxName);
    final current = box.get('totalSpins', defaultValue: 0);
    await box.put('totalSpins', current + 1);
  }

  /// ** Retrieve unlockedBadges
  static Future<List<String>> getUnlockedBadges() async {
    final box = await Hive.openBox(_boxName);
    return List<String>.from(box.get('badges', defaultValue: []));
  }

  /// ** UnlockBadges
  static Future<void> unlockBadge(String badge) async {
    final badges = await getUnlockedBadges();
    if (!badges.contains(badge)) {
      badges.add(badge);
      final box = await Hive.openBox(_boxName);
      await box.put('badges', badges);
    }
  }

  /// Stores the prize log as a list of JSON strings
  static Future<void> setPrizeLog(List<PrizeEntry> entries) async {
    final box = await Hive.openBox(_boxName);
    final data = entries.map((e) => e.toJson()).toList();
    await box.put('prizeLog', data);
  }

  /// Retrieves the stored prize log
  static Future<List<PrizeEntry>> getPrizeLog() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('prizeLog', defaultValue: []);
    if (raw is List) {
      return raw
          .map((e) => PrizeEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Set the prize log filter types
  static Future<void> savePrizeLogFilters({
    String? exportFormat,
    String? badge,
    String? viewRange,
  }) async {
    final box = await Hive.openBox(_boxName);
    if (exportFormat != null) {
      await box.put('prize_export_format', exportFormat);
    }
    if (badge != null) await box.put('prize_filter_badge', badge);
    if (viewRange != null) await box.put('prize_filter_view_range', viewRange);
  }

  /// Retrieve the prize export format
  static Future<String> getExportFormat() async {
    final box = await Hive.openBox(_boxName);
    return box.get('prize_export_format', defaultValue: 'json');
  }

  /// Retrieve the prize badges by filtering
  static Future<String> getFilterBadge() async {
    final box = await Hive.openBox(_boxName);
    return box.get('prize_filter_badge', defaultValue: '');
  }

  /// Retrieve the filter range for prize
  static Future<String> getFilterViewRange() async {
    final box = await Hive.openBox(_boxName);
    return box.get('prize_filter_view_range', defaultValue: 'all');
  }

  /// ** Save spin wheel segment time
  static Future<void> setSegmentFetchTime(DateTime time) async {
    final box = await Hive.openBox(_boxName);
    await box.put('lastSegmentFetchTime', time.toIso8601String());
  }

  /// ** Retrieve spin wheel segment time
  static Future<DateTime?> getSegmentFetchTime() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('lastSegmentFetchTime');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// ** Saves items purchased from the store
  static Future<void> addPurchasedItem(String itemId) async {
    final box = await Hive.openBox('purchased_items');
    await box.put(itemId, true);
  }

  /// ** Check item id for purchase
  static Future<bool> hasItem(String itemId) async {
    final box = await Hive.openBox('purchased_items');
    return box.get(itemId, defaultValue: false);
  }

  /// **Retrieves all purchased items from the store
  Future<List<String>> getAllPurchasedItems() async {
    final box = await Hive.openBox('purchased_items');
    return box.keys.cast<String>().toList();
  }

  /// ** Save power-ups to inventory
  static Future<void> addToInventory(String itemId) async {
    final box = await Hive.openBox<List<String>>('store_data');
    final List<String> current = box.get(_boxName, defaultValue: [])!;
    if (!current.contains(itemId)) {
      current.add(itemId);
      await box.put(_boxName, current);
    }
  }

  /// ** Retrieve power-ups from inventory
  static Future<List<String>> getInventory() async {
    final box = await Hive.openBox<List<String>>('store_data');
    return box.get(_boxName, defaultValue: [])!;
  }

  static Future<bool> isInInventory(String id) async {
    final items = await getStringList('purchased_items') ?? [];
    return items.contains(id);
  }

  /// Sets the confetti theme name
  static Future<void> setConfettiTheme(String theme) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiTheme', theme);
  }

  /// Sets the confetti animation speed
  static Future<void> setConfettiSpeed(double speed) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiSpeed', speed);
  }

  /// Sets the number of confetti particles
  static Future<void> setConfettiParticleCount(int count) async {
    final box = await Hive.openBox(_boxName);
    await box.put('confettiParticleCount', count);
  }

  /// Sets the particle density setting
  static Future<void> setParticleDensity(String density) async {
    final box = await Hive.openBox(_boxName);
    await box.put('particleDensity', density);
  }
}
