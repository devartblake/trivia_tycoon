import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/theme_settings_controller.dart';
import '../../../game/providers/riverpod_providers.dart';

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemePresetList extends ConsumerWidget {
  final void Function(String presetName) onEdit;
  final void Function(String presetName) onDelete;

  const ThemePresetList({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customPresets = ref.watch(themeSettingsProvider.notifier).customPresets;

    if (customPresets.isEmpty) {
      return const Text("No custom themes saved.");
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: customPresets.length,
      itemBuilder: (context, index) {
        final preset = customPresets[index];

        return ListTile(
          title: Text(preset.themeName),
          leading: CircleAvatar(
            backgroundColor: preset.primaryColor,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: preset.secondaryColor,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: "Edit Theme",
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit(preset.themeName),
              ),
              IconButton(
                tooltip: "Delete Theme",
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(preset.themeName),
              ),
            ],
          ),
        );
      },
    );
  }
}
