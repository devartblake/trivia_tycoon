import 'package:hive/hive.dart';

/// Manages confetti theme, speed, particle count, and colors.
class ConfettiSettingsService {
  static const String _boxName = 'settings';
  static const String _confettiThemeKey = 'confettiTheme';
  static const String _confettiSpeedKey = 'confettiSpeed';
  static const String _confettiParticleCountKey = 'confettiParticleCount';
  static const String _confettiColorsKey = 'confettiColors';
  static const String _confettiPresetKey = 'confettiPreset';
  static const String _confettiDensityKey = 'particleDensity';

  Future<Box> _box() async => Hive.openBox(_boxName);

  Future<void> saveTheme(String theme) async {
    final box = await _box();
    await box.put(_confettiThemeKey, theme);
  }

  Future<String> getTheme() async {
    final box = await _box();
    return box.get(_confettiThemeKey, defaultValue: 'default');
  }

  Future<void> saveSpeed(double speed) async {
    final box = await _box();
    await box.put(_confettiSpeedKey, speed);
  }

  Future<double> getSpeed() async {
    final box = await _box();
    return box.get(_confettiSpeedKey, defaultValue: 1.0);
  }

  Future<void> saveParticleCount(int count) async {
    final box = await _box();
    await box.put(_confettiParticleCountKey, count);
  }

  Future<int> getParticleCount() async {
    final box = await _box();
    return box.get(_confettiParticleCountKey, defaultValue: 100);
  }

  Future<void> saveColors(List<int> colors) async {
    final box = await _box();
    await box.put(_confettiColorsKey, colors);
  }

  Future<List<int>> getColors() async {
    final box = await _box();
    return List<int>.from(box.get(_confettiColorsKey, defaultValue: []));
  }

  Future<void> savePreset(String preset) async {
    final box = await _box();
    await box.put(_confettiPresetKey, preset);
  }

  Future<String> getPreset() async {
    final box = await _box();
    return box.get(_confettiPresetKey, defaultValue: 'default');
  }

  Future<void> saveDensity(String density) async {
    final box = await _box();
    await box.put(_confettiDensityKey, density);
  }

  Future<String> getDensity() async {
    final box = await _box();
    return box.get(_confettiDensityKey, defaultValue: 'Auto');
  }
}
