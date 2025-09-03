import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/custom_theme_service.dart';
import '../../core/utils/theme_mapper.dart';
import '../providers/riverpod_providers.dart';

final themeSettingsProvider =
StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeSettings {
  final String themeName;
  final Color primaryColor;
  final Color secondaryColor;
  final Brightness brightness;
  final ColorScheme? colorScheme;
  final Color? scaffoldBackgroundColor;
  final TextTheme? textTheme;

  const ThemeSettings({
    required this.themeName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.brightness,
    this.colorScheme,
    this.scaffoldBackgroundColor,
    this.textTheme,
  });

  ThemeSettings copyWith({
    String? themeName,
    Color? primaryColor,
    Color? secondaryColor,
    Brightness? brightness,
    ColorScheme? colorScheme,
    Color? scaffoldBackgroundColor,
    TextTheme? textTheme,
  }) {
    return ThemeSettings(
      themeName: themeName ?? this.themeName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      brightness: brightness ?? this.brightness,
      colorScheme: colorScheme ?? this.colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      textTheme: textTheme ?? this.textTheme,
    );
  }
}

class ThemeSettingsController extends StateNotifier<ThemeSettings> {
  final CustomThemeService themeService;
  ThemeSettingsController(this.themeService) : super(_defaultTheme) {
    _initialize();
  }

  static const _defaultTheme = ThemeSettings(
    themeName: 'Default',
    primaryColor: Colors.blue,
    secondaryColor: Colors.teal,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(),
    scaffoldBackgroundColor: Colors.blueAccent,
    textTheme: TextTheme(),
  );

  static final List<ThemeSettings> presets = [
    _defaultTheme,
    ThemeSettings(
      themeName: 'Dark',
      primaryColor: Colors.grey,
      secondaryColor: Colors.blueGrey,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(),
      scaffoldBackgroundColor: Colors.black,
      textTheme: TextTheme(),
    ),
    ThemeSettings(
      themeName: 'Sunset',
      primaryColor: Colors.deepOrange,
      secondaryColor: Colors.amber,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(),
      scaffoldBackgroundColor: Colors.deepOrangeAccent,
      textTheme: TextTheme(),
    ),
    ThemeSettings(
      themeName: 'Ocean',
      primaryColor: Colors.cyan,
      secondaryColor: Colors.indigo,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(),
      scaffoldBackgroundColor: Colors.cyanAccent,
      textTheme: TextTheme(),
    ),
    ThemeSettings(
      themeName: 'Neon',
      primaryColor: Colors.purpleAccent,
      secondaryColor: Colors.greenAccent,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(),
      scaffoldBackgroundColor: Colors.purple,
      textTheme: TextTheme(),
    ),
  ];

  List<ThemeSettings> customPresets = [];
  String? _ageGroup;
  String _currentAgeGroup = 'default';

  List<ThemeSettings> get allPresets => [...presets, ...customPresets];
  String get currentAgeGroup => _currentAgeGroup;

  Future<void> _initialize() async {
    await _loadFromPrefs();
    await _loadAgeGroup();
    await loadCustomPresets();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final savedName = await themeService.getThemeName() ?? 'Default';
      final primary = await themeService.getPrimaryColor() ?? Colors.blue;
      final secondary = await themeService.getSecondaryColor() ?? Colors.teal;
      final dark = await themeService.getDarkMode() ?? false;
      _ageGroup = await themeService.getAgeGroup() ?? 'teens';

      state = ThemeSettings(
        themeName: savedName,
        primaryColor: primary,
        secondaryColor: secondary,
        brightness: dark ? Brightness.dark : Brightness.light,
        colorScheme: dark ? ColorScheme.dark() : ColorScheme.light(),
      );

      applyAgeGroupTheme(_ageGroup!);
    } catch (e) {
      state = _defaultTheme;
    }
  }

  Future<void> _loadAgeGroup() async {
    _ageGroup = await themeService.getAgeGroup() ?? 'teens';
    applyAgeGroupTheme(_ageGroup!);
  }

  void applyAgeGroupTheme(String ageGroup) {
    state = ThemeMapper.getThemeForAgeGroup(ageGroup);
  }

  Future<void> setAgeGroup(String ageGroup) async {
    _ageGroup = ageGroup;
    await themeService.setAgeGroup(ageGroup);
    applyAgeGroupTheme(ageGroup);
  }

  Future<void> setCurrentAgeGroup(String currentAgeGroup) async {
    _currentAgeGroup = currentAgeGroup;
    await themeService.setAgeGroup( currentAgeGroup);
    state = ThemeMapper.getThemeForAgeGroup(currentAgeGroup);
  }

  Future<void> updateTheme(ThemeSettings newSettings) async {
    state = newSettings;
    await themeService.setThemeSettings(
      name: newSettings.themeName,
      primary: newSettings.primaryColor,
      secondary: newSettings.secondaryColor,
      isDark: newSettings.brightness == Brightness.dark,
    );
  }

  void toggleBrightness() {
    final isDark = state.brightness == Brightness.dark;
    updateTheme(state.copyWith(
      brightness: isDark ? Brightness.light : Brightness.dark,
      colorScheme: isDark ? ColorScheme.light() : ColorScheme.dark(),
    ));
  }

  void setPrimaryColor(Color color) {
    updateTheme(state.copyWith(primaryColor: color));
  }

  void setSecondaryColor(Color color) {
    updateTheme(state.copyWith(secondaryColor: color));
  }

  void setThemeName(String name) {
    updateTheme(state.copyWith(themeName: name));
  }

  Future<void> loadCustomPresets() async {
    customPresets = await themeService.getAllCustomThemes();
  }

  Future<void> saveCustomPreset(ThemeSettings preset) async {
    await themeService.saveCustomTheme(preset);
    await loadCustomPresets();
  }

  Future<void> deletePreset(String name) async {
    await themeService.deleteCustomTheme(name);
    await loadCustomPresets();
  }
}