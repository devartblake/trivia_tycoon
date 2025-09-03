import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../confetti/utils/confetti_storage.dart';
import '../../confetti/confetti.dart';
import '../../confetti/core/presets/confetti_presets.dart';
import '../../confetti/utils/confetti_performance.dart';
import 'confetti_theme.dart';

class ConfettiController extends ChangeNotifier with DiagnosticableTreeMixin{
  double speed = 1.0;
  bool isPlaying = false;
  int particleCount = 100;
  bool isRandomTheme = false;
  List<Color> customColors = [];
  String _particleDensity = 'Auto';
  ConfettiSettings _settings = ConfettiSettings();
  ConfettiTheme get theme => currentTheme;
  ConfettiTheme currentTheme = ConfettiPresets.celebration;


  ConfettiController() {
    _loadSavedSettings(); 
  }

  /// **Load stored confetti settings**
  Future<void> _loadSavedSettings() async {
    _settings = await ConfettiStorage.loadSettings();

    // Apply loaded settings
    _particleDensity = await AppSettings.getParticleDensity();
    String? savedThemeName = await AppSettings.getConfettiTheme();
    speed = await AppSettings.getConfettiSpeed() ?? currentTheme.speed;
    particleCount = await AppSettings.getConfettiParticleCount() ?? currentTheme.density;

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
    if (!isPlaying) {
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
}