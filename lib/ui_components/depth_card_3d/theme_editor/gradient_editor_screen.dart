import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/depth_card_3d/depth_card.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../../color_picker/ui/color_picker_component.dart';
import '../theme_editor/depth_card_theme_selector.dart';

class GradientEditorScreen extends ConsumerStatefulWidget {
  const GradientEditorScreen({super.key});

  @override
  ConsumerState<GradientEditorScreen> createState() => _GradientEditorScreenState();
}

class _GradientEditorScreenState extends ConsumerState<GradientEditorScreen> {
  late DepthCardTheme theme;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(profileAvatarControllerProvider);
    theme = controller.depthCardTheme;
  }

  Future<void> _saveTheme() async {
    await AppSettings.setDepthCardTheme(theme.name);
    ref.read(profileAvatarControllerProvider.notifier).setDepthCardTheme(theme);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Theme saved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customize Avatar Theme"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save Theme",
            onPressed: _saveTheme,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Live Preview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Center(
            // Live 3D Preview
            child: DepthCard3D(
              config: DepthCardConfig(
                modelAssetPath: 'assets/models/avatars/character1.glb',
                text: 'Live Preview',
                theme: theme,
                height: 220,
                width: 220,
                borderRadius: 16,
                backgroundImage: const AssetImage('assets/images/backgrounds/3d_placeholder.jpg'),
                parallaxDepth: 0.12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Theme Presets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Theme Preset Selector
          DepthCardThemeSelector(
            selectedName: theme.name,
            onThemeSelected: (selected) {
              setState(() {
                theme = selected;
              });
              ref.read(profileAvatarControllerProvider.notifier).setDepthCardTheme(selected);
            },
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Sample sliders and color pickers
          ListTile(
            title: const Text("Elevation"),
            subtitle: Slider(
              min: 0,
              max: 50,
              value: theme.elevation,
              onChanged: (val) {
                setState(() {
                  theme = theme.copyWith(elevation: val);
                });
              },
            ),
          ),
          SwitchListTile(
            value: theme.glowEnabled,
            onChanged: (val) {
              setState(() {
                theme = theme.copyWith(glowEnabled: val);
              });
            },
            title: const Text("Enable Glow"),
          ),
          // You can expand with color pickers using color picker
          const Divider(),
          const Text("Customize Colors", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Color Picker for Shadow Color
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text("Shadow Color:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ColorPickerComponent(
                      selectedColors: [theme.shadowColor],
                      onColorsChanged: (colors) {
                        if (colors.isNotEmpty) {
                          setState(() {
                            theme = theme.copyWith(shadowColor: colors.first);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text("Text Color:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ColorPickerComponent(
                      selectedColors: [theme.textColor],
                      onColorsChanged: (colors) {
                        if (colors.isNotEmpty) {
                          setState(() {
                            theme = theme.copyWith(textColor: colors.first);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text("Overlay Color:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ColorPickerComponent(
                      selectedColors: [theme.overlayColor],
                      onColorsChanged: (colors) {
                        if (colors.isNotEmpty) {
                          setState(() {
                            theme = theme.copyWith(overlayColor: colors.first);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text("Reset to Default"),
                    onPressed: () {
                      setState(() {
                        theme = DepthCardTheme.presets[0];
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                    onPressed: _saveTheme,
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
