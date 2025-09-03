import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/color_picker/models/color_palette.dart';
import '../core/color_picker_settings.dart';
import '../utils/color_storage.dart';
import 'color_picker_component.dart';

class ColorSettingsDialog extends StatefulWidget {
  final ColorPickerSettings settings;
  final Function(ColorPickerSettings) onSettingsUpdated;
  final Function(ColorPalette) onPaletteSelected;

  const ColorSettingsDialog({
    super.key,
    required this.settings,
    required this.onSettingsUpdated,
    required this.onPaletteSelected,
  });

  @override
  _ColorSettingsDialogState createState() => _ColorSettingsDialogState();
}

class _ColorSettingsDialogState extends State<ColorSettingsDialog> {
  late ColorPickerSettings _localSettings;
  late String _selectedPalette;
  List<String> _paletteNames = [];

  @override
  void initState() {
    super.initState();
    _loadPalettes();
    _localSettings = widget.settings;
  }

  /// **📥 Load available palettes from storage**
  void _loadPalettes() async {
    List<String> palettes = await ColorStorage.getAllPaletteNames();
    setState(() {
      _paletteNames = palettes;
      _selectedPalette = palettes.isNotEmpty ? palettes.first : "Default";
    });
  }

  /// **🆕 Show Palette Creation Dialog**
  void _createNewPalette() async {
    TextEditingController paletteNameController = TextEditingController();
    List<Color> selectedColors = [];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Palette"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paletteNameController,
                decoration: const InputDecoration(labelText: "Palette Name"),
              ),
              const SizedBox(height: 8),
              // Use new Color Picker UI here
              ColorPickerComponent(
                selectedColors: _localSettings.colors,
                onColorsChanged: (colors) {
                  setState(() {
                    _localSettings = _localSettings.copyWith(colors: colors);
                  });
                  widget.onSettingsUpdated(_localSettings);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String name = paletteNameController.text.trim();
                if (name.isNotEmpty && selectedColors.isNotEmpty) {
                  ColorPalette newPalette = ColorPalette(name: name, colors: selectedColors);
                  await ColorStorage.savePalette(newPalette);
                  _loadPalettes(); // Refresh palette list
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// **🔄 Apply selected palette**
  void _applyPalette(String paletteName) async {
    ColorPalette? palette = await ColorStorage.getPalette(paletteName);
    if (palette != null) {
      setState(() {
        _selectedPalette = paletteName;
        _localSettings = _localSettings.copyWith(colors: palette.colors);
      });
      widget.onSettingsUpdated(_localSettings);
    }
  }

  /// **🎨 Update local settings**
  void _updateSetting(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'pickerMode':
          _localSettings = _localSettings.copyWith(pickerMode: value);
          break;
        case 'useCustomPalette':
          _localSettings = _localSettings.copyWith(useCustomPalette: value);
          break;
      }
    });
    widget.onSettingsUpdated(_localSettings);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Color Picker Settings"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// **🆕 Palette Selection + Create Button**
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedPalette,
                  items: _paletteNames.map((palette) {
                    return DropdownMenuItem(
                      value: palette,
                      child: Text("Palette: $palette"),
                    );
                  }).toList(),
                  onChanged: (value) => _applyPalette(value!),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _createNewPalette,
              ),
            ],
          ),

          /// **🎨 Palette Selection Dropdown**
          DropdownButton<String>(
            value: _selectedPalette,
            items: _paletteNames.map((palette) {
              return DropdownMenuItem(
                value: palette,
                child: Text("Palette: $palette"),
              );
            }).toList(),
            onChanged: (value) => _applyPalette(value!),
          ),

          /// **Picker Mode Selection**
          DropdownButton<String>(
            value: _localSettings.pickerMode,
            items: ["wheel", "grid", "sliders"].map((mode) {
              return DropdownMenuItem(
                value: mode,
                child: Text("Picker Mode: ${mode.toUpperCase()}"),
              );
            }).toList(),
            onChanged: (value) => _updateSetting('pickerMode', value),
          ),

          /// **Custom Palette Toggle**
          SwitchListTile(
            title: const Text("Use Custom Palette"),
            value: _localSettings.useCustomPalette,
            onChanged: (value) => _updateSetting('useCustomPalette', value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            ColorStorage.savePickerSettings(_localSettings);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
