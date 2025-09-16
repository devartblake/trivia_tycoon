import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../confetti/utils/confetti_storage.dart';
import '../../confetti/confetti.dart';
import '../../confetti/core/presets/confetti_presets.dart';
import '../../confetti/utils/confetti_performance.dart';
import 'confetti_theme.dart';

class ConfettiController extends ChangeNotifier with DiagnosticableTreeMixin {
  double speed = 1.0;
  bool isPlaying = false;
  int particleCount = 100;
  bool isRandomTheme = false;
  List<Color> customColors = [];
  String _particleDensity = 'Auto';
  ConfettiSettings _settings = ConfettiSettings();
  ConfettiTheme get theme => currentTheme;
  ConfettiTheme currentTheme = ConfettiPresets.celebration;

  // Enhanced state tracking
  bool _isPaused = false;
  DateTime? _lastSaveTime;

  ConfettiController() {
    _loadSavedSettings();
  }

  /// **Load stored confetti settings**
  Future<void> _loadSavedSettings() async {
    try {
      _settings = await ConfettiStorage.loadSettings();

      // Apply loaded settings
      _particleDensity = await AppSettings.getParticleDensity();
      String? savedThemeName = await AppSettings.getConfettiTheme();
      speed = await AppSettings.getConfettiSpeed();
      particleCount = await AppSettings.getConfettiParticleCount();

      // Apply stored or default theme
      if (savedThemeName.isNotEmpty) {
        currentTheme = ConfettiPresets.getPresetByName(savedThemeName);
      }

      // Auto-detect performance-based density if needed
      if (_particleDensity == 'Auto') {
        _particleDensity = ConfettiPerformance().getPerformanceCategory();
      }

      _applyDensitySettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load confetti settings: $e');
    }
  }

  /// **Update and persist confetti settings**
  void updateSettings(ConfettiSettings newSettings) {
    _settings = newSettings;
    ConfettiStorage.saveSettings(newSettings);
    notifyListeners();
  }

  void _applyDensitySettings() {
    int density;
    switch (_particleDensity) {
      case 'Low':
        density = 15;
        break;
      case 'Medium':
        density = 30;
        break;
      case 'High':
        density = 50;
        break;
      default:
        density = 30;
    }
    // Update the particle count based on the performance setting.
    particleCount = density;
  }

  /// **Persist particle density setting**
  void setParticleDensity(String density) async {
    _particleDensity = density;
    _settings = _settings.copyWith(density: double.parse(density));
    await ConfettiStorage.saveSettings(_settings);
    _applyDensitySettings();
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('Particle Density', _particleDensity));
    properties.add(DoubleProperty('Speed', currentTheme.speed));
    properties.add(IntProperty('Density', currentTheme.density));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ConfettiController(density: $_particleDensity, speed: $speed, particleDensity: $particleCount)';
  }

  /// **Starts the confetti animation.**
  void play() {
    if (!isPlaying && !_isPaused) {
      isPlaying = true;
      if (isRandomTheme) {
        // Shuffle the presets list and select the first theme.
        var themes = ConfettiPresets.allPresets.toList();
        themes.shuffle();
        currentTheme = themes.first;
      }
      notifyListeners();
    }
  }

  /// Alias for play(), so that ConfettiPreview can call start().
  void start() {
    play();
  }

  /// Stops the confetti animation.
  void stop() {
    isPlaying = false;
    notifyListeners();
  }

  /// **Sets the current theme and persists it.**
  void setTheme(ConfettiTheme theme) {
    currentTheme = theme;
    isRandomTheme = false;
    _settings = _settings.copyWith(
      colors: theme.colors,
      shapes: theme.shapes,
      speed: theme.speed,
      density: theme.density.toDouble(),
    );
    ConfettiStorage.saveSettings(_settings);
    notifyListeners();
  }

  /// Alias fo the setTheme, to allow for update semantics.
  void updateTheme(ConfettiTheme newTheme) {
    setTheme(newTheme);
  }

  void toggleRandomTheme() {
    isRandomTheme = !isRandomTheme;
    notifyListeners();
  }

  void setSpeed(double newSpeed) {
    speed = newSpeed;
    _settings = _settings.copyWith(speed: newSpeed);
    ConfettiStorage.saveSettings(_settings);
    notifyListeners();
  }

  void setParticleCount(int count) {
    particleCount = count;
    _settings = _settings.copyWith(density: count.toDouble());
    ConfettiStorage.saveSettings(_settings);
    notifyListeners();
  }

  void setCustomColors(List<Color> colors) {
    customColors = colors;
    _settings = _settings.copyWith(colors: colors);
    ConfettiStorage.saveSettings(_settings);
    notifyListeners();
  }

  /// LIFECYCLE METHOD: Save confetti state when app backgrounded
  /// Called by AppLifecycleObserver when app goes to background
  Future<void> saveConfettiState() async {
    try {
      // Stop any active confetti animation to save battery
      if (isPlaying) {
        stop();
      }

      // Save current settings
      await ConfettiStorage.saveSettings(_settings);

      // Save current theme
      await AppSettings.setConfettiTheme(currentTheme.name);
      await AppSettings.setConfettiSpeed(speed);
      await AppSettings.setConfettiParticleCount(particleCount);
      await AppSettings.setParticleDensity(_particleDensity);

      // Create state snapshot
      final stateSnapshot = {
        'speed': speed,
        'particleCount': particleCount,
        'particleDensity': _particleDensity,
        'isRandomTheme': isRandomTheme,
        'currentTheme': currentTheme.name,
        'customColors': customColors.map((c) => c.value).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await AppSettings.setString('confetti_state_snapshot', stateSnapshot.toString());
      _lastSaveTime = DateTime.now();

      debugPrint('Confetti state saved successfully');
    } catch (e) {
      debugPrint('Failed to save confetti state: $e');
    }
  }

  /// LIFECYCLE METHOD: Validate confetti settings when app resumes
  /// Called by AppLifecycleObserver when app resumes from background
  Future<void> validateConfettiSettings() async {
    try {
      // Validate current settings
      await _validateSettingsIntegrity();

      // Check performance and adjust settings if needed
      await _checkPerformanceOptimization();

      // Resume normal operation
      _isPaused = false;

      debugPrint('Confetti settings validation completed');
    } catch (e) {
      debugPrint('Confetti settings validation failed: $e');
      await _resetToDefaults();
    }
  }

  /// Validate settings integrity
  Future<void> _validateSettingsIntegrity() async {
    try {
      bool needsRepair = false;

      // Validate speed
      if (speed <= 0 || speed > 10) {
        speed = 1.0;
        needsRepair = true;
      }

      // Validate particle count
      if (particleCount <= 0 || particleCount > 500) {
        particleCount = 100;
        needsRepair = true;
      }

      // Validate particle density
      if (!['Auto', 'Low', 'Medium', 'High'].contains(_particleDensity)) {
        _particleDensity = 'Auto';
        needsRepair = true;
      }

      // Validate theme
      if (currentTheme == null) {
        currentTheme = ConfettiPresets.celebration;
        needsRepair = true;
      }

      if (needsRepair) {
        await _saveValidatedSettings();
        debugPrint('Confetti settings integrity restored');
      }
    } catch (e) {
      debugPrint('Failed to validate confetti settings: $e');
    }
  }

  /// Check and optimize performance settings
  Future<void> _checkPerformanceOptimization() async {
    try {
      // Auto-adjust density based on performance if set to Auto
      if (_particleDensity == 'Auto') {
        final newCategory = ConfettiPerformance().getPerformanceCategory();
        if (newCategory != _particleDensity) {
          _particleDensity = newCategory;
          _applyDensitySettings();
          await ConfettiStorage.saveSettings(_settings);
        }
      }

      // Limit particle count on low-end devices
      final performanceCategory = ConfettiPerformance().getPerformanceCategory();
      if (performanceCategory == 'Low' && particleCount > 20) {
        particleCount = 15;
        await ConfettiStorage.saveSettings(_settings);
      }
    } catch (e) {
      debugPrint('Performance optimization failed: $e');
    }
  }

  /// Save validated settings
  Future<void> _saveValidatedSettings() async {
    _settings = _settings.copyWith(
      speed: speed,
      density: particleCount.toDouble(),
      colors: currentTheme.colors,
      shapes: currentTheme.shapes,
    );

    await ConfettiStorage.saveSettings(_settings);
    await AppSettings.setConfettiSpeed(speed);
    await AppSettings.setConfettiParticleCount(particleCount);
    await AppSettings.setParticleDensity(_particleDensity);
  }

  /// Reset to default settings
  Future<void> _resetToDefaults() async {
    try {
      speed = 1.0;
      particleCount = 100;
      _particleDensity = 'Auto';
      isRandomTheme = false;
      customColors = [];
      currentTheme = ConfettiPresets.celebration;

      _settings = ConfettiSettings();
      await ConfettiStorage.saveSettings(_settings);

      debugPrint('Confetti settings reset to defaults');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset confetti settings: $e');
    }
  }

  /// Pause confetti (for battery saving)
  void pauseConfetti() {
    _isPaused = true;
    if (isPlaying) {
      stop();
    }
  }

  /// Resume confetti operations
  void resumeConfetti() {
    _isPaused = false;
  }

  /// Pause method (alias for pauseConfetti for AppLifecycle consistency)
  void pause() {
    pauseConfetti();
  }

  /// Resume method (alias for resumeConfetti for AppLifecycle consistency)
  void resume() {
    resumeConfetti();
  }

  /// Get confetti statistics
  Map<String, dynamic> getConfettiStats() {
    return {
      'speed': speed,
      'particleCount': particleCount,
      'particleDensity': _particleDensity,
      'currentTheme': currentTheme.name,
      'isPlaying': isPlaying,
      'isPaused': _isPaused,
      'isRandomTheme': isRandomTheme,
      'customColorsCount': customColors.length,
      'lastSave': _lastSaveTime?.toIso8601String(),
    };
  }

  /// Export confetti settings for backup
  Map<String, dynamic> exportConfettiSettings() {
    return {
      'speed': speed,
      'particleCount': particleCount,
      'particleDensity': _particleDensity,
      'currentTheme': currentTheme.name,
      'isRandomTheme': isRandomTheme,
      'customColors': customColors.map((c) => c.value).toList(),
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import confetti settings from backup
  Future<void> importConfettiSettings(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('speed')) speed = data['speed'].toDouble();
      if (data.containsKey('particleCount')) particleCount = data['particleCount'];
      if (data.containsKey('particleDensity')) _particleDensity = data['particleDensity'];
      if (data.containsKey('isRandomTheme')) isRandomTheme = data['isRandomTheme'];

      if (data.containsKey('currentTheme')) {
        currentTheme = ConfettiPresets.getPresetByName(data['currentTheme']);
      }

      if (data.containsKey('customColors')) {
        customColors = (data['customColors'] as List)
            .map((colorValue) => Color(colorValue))
            .toList();
      }

      await _saveValidatedSettings();
      notifyListeners();

      debugPrint('Confetti settings imported successfully');
    } catch (e) {
      debugPrint('Failed to import confetti settings: $e');
      rethrow;
    }
  }
}
