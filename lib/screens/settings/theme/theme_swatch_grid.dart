import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

import '../../../game/controllers/theme_settings_controller.dart';

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeSwatchGrid extends ConsumerWidget {
  const ThemeSwatchGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(themeSettingsProvider.notifier);
    final current = ref.watch(themeSettingsProvider);

    final swatches = [
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.amber,
      Colors.red,
      Colors.cyan,
      Colors.yellow,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        const Text("Primary Color", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: swatches.map((color) {
            final isSelected = color.value == current.primaryColor.value;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)]
                    : [],
              ),
              child: GestureDetector(
                onTap: () => controller.setPrimaryColor(color),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text("Secondary Color", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: swatches.map((color) {
            final isSelected = color.value == current.secondaryColor.value;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)]
                    : [],
              ),
              child: GestureDetector(
                onTap: () => controller.setSecondaryColor(color),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Customize Theme"),
            onPressed: () => context.push('/theme-editor'),
          ),
        )
      ],
    );
  }
}