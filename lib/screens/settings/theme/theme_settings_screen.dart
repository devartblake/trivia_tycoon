import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/theme_settings_controller.dart';
import '../../../game/providers/riverpod_providers.dart';
import 'theme_selector_dropdown.dart';
import 'theme_swatch_grid.dart';
import 'theme_color_picker.dart';

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎨 Theme Settings"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔵 Live Theme Preview Banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: currentTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentTheme.primaryColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.color_lens, color: currentTheme.primaryColor),
                const SizedBox(width: 10),
                Text("Current Theme: ${currentTheme.themeName}",
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),

          const Text("Select Theme Style", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const ThemeSelectorDropdown(),

          const Divider(height: 30),

          /// 🎨 Primary Color Picker (collapsible)
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text("Customize Primary Color"),
            children: const [
              ThemeColorPicker(isPrimary: true),
            ],
          ),

          const SizedBox(height: 10),

          /// 🎨 Secondary Color Picker (collapsible)
          ExpansionTile(
            initiallyExpanded: false,
            title: const Text("Customize Secondary Color"),
            children: const [
              ThemeColorPicker(isPrimary: false),
            ],
          ),

          const Divider(height: 30),

          const Text("Choose Swatch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const ThemeSwatchGrid(),
        ],
      ),
    );
  }
}
