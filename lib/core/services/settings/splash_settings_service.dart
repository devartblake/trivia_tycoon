import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/navigation/splash_type.dart';

/// Service responsible for storing and retrieving splash screen preferences.
class SplashSettingsService {
  static const _boxName = 'settings';
  static const _key = 'splash_type';

  /// Sets the splash screen type.
  Future<void> setSplashType(SplashType type) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, type.name);
  }

  /// Gets the saved splash screen type, defaults to [SplashType.fortuneWheel].
  Future<SplashType> getSplashType() async {
    final box = await Hive.openBox(_boxName);
    final name = box.get(_key);
    return SplashType.values.firstWhere(
          (e) => e.name == name,
      orElse: () => SplashType.fortuneWheel,
    );
  }
}
