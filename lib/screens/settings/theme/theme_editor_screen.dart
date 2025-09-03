import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';
import '../../../game/providers/riverpod_providers.dart';

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeEditorScreen extends ConsumerWidget {
  const ThemeEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(themeSettingsProvider.notifier);
    final settings = ref.watch(themeSettingsProvider);
    final allPresets = ThemeSettingsController.presets + controller.customPresets;

    final isDark = settings.brightness == Brightness.dark;

    Future<void> saveTheme(ThemeSettings settings, String name) async {
      final newPreset = settings.copyWith(themeName: name);
      await controller.saveCustomPreset(newPreset);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎨 Customize Theme"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Theme',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Save Theme"),
                  content: TextField(
                    decoration: const InputDecoration(labelText: "Theme Name"),
                    onSubmitted: (value) async {
                      if (value.isNotEmpty) {
                        await saveTheme(settings, value);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Theme saved!")),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🌈 LIVE PREVIEW SECTION
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [settings.primaryColor, settings.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              alignment: Alignment.center,
              child: Text(
                settings.themeName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// 🖍️ PRIMARY COLOR PICKER
            Text("Primary Color", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: allPresets.map((preset) {
                final selected = preset.primaryColor == settings.primaryColor;
                return GestureDetector(
                  onTap: () => controller.setPrimaryColor(preset.primaryColor),
                    onLongPress: () async {
                      final result = await context.push<Color>('/theme-color-picker');
                      if (result != null) {
                        controller.setPrimaryColor(result);
                      }
                    },
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [BoxShadow(color: preset.primaryColor.withOpacity(0.6), blurRadius: 10)]
                          : [],
                    ),
                    child: CircleAvatar(
                      backgroundColor: preset.primaryColor,
                      radius: 24,
                      child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            /// 🎨 SECONDARY COLOR PICKER
            Text("Secondary Color", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: allPresets.map((preset) {
                final selected = preset.secondaryColor == settings.secondaryColor;
                return GestureDetector(
                  onTap: () => controller.setSecondaryColor(preset.secondaryColor),
                    onLongPress: () async {
                      final result = await context.push<Color>('/theme-color-picker');
                      if (result != null) {
                        controller.setPrimaryColor(result);
                      }
                    },
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [BoxShadow(color: preset.secondaryColor.withOpacity(0.6), blurRadius: 10)]
                          : [],
                    ),
                    child: CircleAvatar(
                      backgroundColor: preset.secondaryColor,
                      radius: 24,
                      child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),

            TextField(
              decoration: const InputDecoration(
                labelText: "Custom Theme Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.setThemeName(value);
              },
            ),

            const SizedBox(height: 30),

            /// 🌙 DARK MODE TOGGLE
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: isDark,
              onChanged: (_) => controller.toggleBrightness(),
              secondary: const Icon(Icons.brightness_6),
            ),
          ],
        ),
      ),
    );
  }
}
