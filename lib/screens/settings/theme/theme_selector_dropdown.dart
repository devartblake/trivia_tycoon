import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';
import '../../../game/providers/riverpod_providers.dart';

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeSelectorDropdown extends ConsumerWidget {
  const ThemeSelectorDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeSettingsProvider);
    final controller = ref.read(themeSettingsProvider.notifier);
    final allPresets = ThemeSettingsController.presets + controller.customPresets;


    return DropdownButtonFormField<String>(
      value: currentTheme.themeName,
      decoration: const InputDecoration(
        labelText: "Theme Style",
        border: OutlineInputBorder(),
      ),
      items: allPresets.map((preset) {
        return DropdownMenuItem<String>(
          value: preset.themeName,
          child: Text(preset.themeName),
        );
      }).toList(),
      onChanged: (selectedName) {
        final selectedPreset = allPresets.firstWhere(
              (preset) => preset.themeName == selectedName,
          orElse: () => allPresets.first,
        );
        controller.updateTheme(selectedPreset); // 🔄 Live update
      },
    );
  }
}