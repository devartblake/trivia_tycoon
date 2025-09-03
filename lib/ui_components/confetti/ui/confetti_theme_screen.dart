import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/coin_balance_notifier.dart';
import 'package:trivia_tycoon/ui_components/confetti/confetti.dart';
import 'package:trivia_tycoon/ui_components/confetti/utils/confetti_settings_storage.dart';
import '../core/confetti_theme.dart';
import '../ui/confetti_preview.dart';
import '../ui/confetti_color_picker.dart';
import '../ui/confetti_shape_picker.dart';
import '../ui/confetti_physics_controls.dart';
import '../ui/confetti_save_button.dart';
import '../core/presets/confetti_presets.dart';

class ConfettiThemeScreen extends ConsumerStatefulWidget {
  const ConfettiThemeScreen({super.key});

  @override
  ConsumerState<ConfettiThemeScreen> createState() => _ConfettiThemeScreenState();
}

class _ConfettiThemeScreenState extends ConsumerState<ConfettiThemeScreen> {
  late final ConfettiSettingsStorage _storage;
  ConfettiSettings _settings = ConfettiSettings(); // Stores user preferences
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    final generalStorage = ref.read(generalKeyValueStorageProvider);
    _storage = ConfettiSettingsStorage(storage: generalStorage);
    _controller = ConfettiController(); // Manages the confetti effect
  }

  /// Updates settings and refreshes the UI
  void _updateSettings(ConfettiSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  /// Applies a preset when selected
  void _applyPreset(ConfettiTheme preset) {
    setState(() {
      _settings = ConfettiSettings.fromTheme(preset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confetti Theme Editor")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **🎨 Preset Selector (Horizontal Scroll)**
            _buildPresetSelector(),

            /// **📌 Collapsible Sections**
            _buildExpandableSection("Theme Name", _buildThemeNameInput()),
            _buildExpandableSection("Color Selection", ConfettiColorPicker(
              selectedColors: _settings.colors,
              onColorsChanged: (colors) => _updateSettings(_settings.copyWith(colors: colors)),
            ) as Widget),
            _buildExpandableSection("Shape Selection", ConfettiShapePicker(
              availableShapes: ConfettiShapeType.values,
              selectedShapes: _settings.shapes,
              onShapesChanged: (List<ConfettiShapeType> shapes) => _updateSettings(_settings.copyWith(shapes: shapes)),
            ) as Widget),
            _buildExpandableSection("Physics Settings", ConfettiPhysicsControls(
              speed: _settings.speed,
              gravity: _settings.gravity,
              wind: _settings.wind,
              onChanged: (speed, gravity, wind) {
                _updateSettings(_settings.copyWith(speed: speed, gravity: gravity, wind: wind));
              },
            ) as Widget),
            _buildExpandableSection("Size & Density", _buildDensityControls()),

            /// **🎆 Live Preview**
            _buildExpandableSection("Live Preview", ConfettiPreview(
              settings: _settings,
              controller: _controller,
              theme: ConfettiTheme(
                name: _settings.name,
                colors: _settings.colors,
                shapes: _settings.shapes,
                speed: _settings.speed,
                gravity: _settings.enableGravity ? 1.0 : 0.0, // Convert boolean to a usable value.
                wind: _settings.wind,  // Set default wind (or add wind support in '_settings').
                density: _settings.density.toInt(), // Convert density to int if needed.
                useImages: _settings.useImages,
              ),
            ) as Widget),

            ExpansionTile(
              title: const Text("Saved Themes"),
              children: [
                FutureBuilder(
                  future: _storage.loadAllThemes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final themes = snapshot.data!;
                    return Wrap(
                      spacing: 8,
                      children: themes.map((t) => ElevatedButton(
                        onPressed: () => _applyPreset(ConfettiTheme.fromSettings(t)),
                        child: Text(t.name),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),

            /// **💾 Save & Apply Button**
            ConfettiSaveButton(
              settings: _settings,
              onSave: () async {
                await _storage.saveTheme(_settings.name, _settings);
                // Save settings and apply them
                _controller.updateSettings(_settings);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Theme saved successfully!")),
                );
              },
            ),
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  /// **Builds the preset selection row**
  Widget _buildPresetSelector() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ConfettiPresets.allPresets.map((preset) {
          return GestureDetector(
            onTap: () => _applyPreset(preset),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Text(preset.name, style: TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// **Creates collapsible sections using ExpansionTile**
  Widget _buildExpandableSection(String title, Widget child) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      children: [Padding(padding: EdgeInsets.all(8.0), child: child)],
    );
  }

  /// **Theme Name Input Field**
  Widget _buildThemeNameInput() {
    return TextField(
      decoration: InputDecoration(labelText: "Enter Theme Name"),
      onChanged: (name) => _updateSettings(_settings.copyWith(name: name)),
    );
  }

  /// **Density & Size Controls**
  Widget _buildDensityControls() {
    return Column(
      children: [
        Text("Density: ${_settings.density}"),
        Slider(
          value: _settings.density.toDouble(),
          min: 10,
          max: 200,
          onChanged: (value) => _updateSettings(_settings.copyWith(density: value)),
        ),
      ],
    );
  }

  /// ** Build version **
  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Text(
        "Theme Version: ${_settings.schemaVersion} (v${_settings.schemaVersion == 2 ? "Latest" : "Legacy"})",
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
      ),
    );
  }

}
