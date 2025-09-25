import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  State<ColorSettingsDialog> createState() => _ColorSettingsDialogState();
}

class _ColorSettingsDialogState extends State<ColorSettingsDialog>
    with TickerProviderStateMixin {
  late ColorPickerSettings _localSettings;
  late String _selectedPalette;
  List<String> _paletteNames = [];
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localSettings = widget.settings;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _loadPalettes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPalettes() async {
    try {
      List<String> palettes = await ColorStorage.getAllPaletteNames();
      if (mounted) {
        setState(() {
          _paletteNames = palettes;
          _selectedPalette = palettes.isNotEmpty ? palettes.first : "Default";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paletteNames = ["Default"];
          _selectedPalette = "Default";
          _isLoading = false;
        });
      }
    }
  }

  void _createNewPalette() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaletteCreationDialog(
        initialColors: _localSettings.colors,
      ),
    );

    if (result != null) {
      final String name = result['name'];
      final List<Color> colors = result['colors'];

      try {
        ColorPalette newPalette = ColorPalette(name: name, colors: colors);
        await ColorStorage.savePalette(newPalette);
        _loadPalettes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text("Palette '$name' created successfully!"),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error creating palette: $e"),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  void _applyPalette(String paletteName) async {
    try {
      ColorPalette? palette = await ColorStorage.getPalette(paletteName);
      if (palette != null && mounted) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPalette = paletteName;
          _localSettings = _localSettings.copyWith(colors: palette.colors);
        });
        widget.onSettingsUpdated(_localSettings);
        widget.onPaletteSelected(palette);
      }
    } catch (e) {
      debugPrint('Error applying palette: $e');
    }
  }

  void _updateSetting(String key, dynamic value) {
    HapticFeedback.selectionClick();
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _slideAnimation.value,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade400.withOpacity(0.1),
                          Colors.purple.shade400.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Color Picker Settings",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Loading palettes...",
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Palette Management Section
                          _buildSection(
                            "Color Palettes",
                            Icons.palette_rounded,
                            Colors.pink,
                            [
                              _buildPaletteSelector(colorScheme),
                              const SizedBox(height: 16),
                              _buildCreatePaletteButton(colorScheme),
                            ],
                            colorScheme,
                          ),

                          const SizedBox(height: 24),

                          // Picker Mode Section
                          _buildSection(
                            "Picker Mode",
                            Icons.tune_rounded,
                            Colors.teal,
                            [
                              _buildPickerModeSelector(colorScheme),
                            ],
                            colorScheme,
                          ),

                          const SizedBox(height: 24),

                          // Additional Settings Section
                          _buildSection(
                            "Preferences",
                            Icons.settings_outlined,
                            Colors.orange,
                            [
                              _buildCustomPaletteToggle(colorScheme),
                            ],
                            colorScheme,
                          ),
                        ],
                      ),
                    ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text("Cancel"),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              try {
                                await ColorStorage.savePickerSettings(_localSettings);
                                Navigator.pop(context);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                          SizedBox(width: 12),
                                          Text("Settings saved successfully!"),
                                        ],
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error saving settings: $e"),
                                      backgroundColor: Colors.red.shade600,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text("Save"),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      String title,
      IconData icon,
      Color accentColor,
      List<Widget> children,
      ColorScheme colorScheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPaletteSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButton<String>(
        value: _selectedPalette,
        isExpanded: true,
        underline: const SizedBox(),
        items: _paletteNames.map((palette) {
          return DropdownMenuItem(
            value: palette,
            child: Text(palette),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) _applyPalette(value);
        },
      ),
    );
  }

  Widget _buildCreatePaletteButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _createNewPalette,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Create New Palette"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: Colors.pink.withOpacity(0.5)),
          foregroundColor: Colors.pink,
        ),
      ),
    );
  }

  Widget _buildPickerModeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButton<String>(
        value: _localSettings.pickerMode,
        isExpanded: true,
        underline: const SizedBox(),
        items: ["wheel", "grid", "sliders"].map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(mode.toUpperCase()),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) _updateSetting('pickerMode', value);
        },
      ),
    );
  }

  Widget _buildCustomPaletteToggle(ColorScheme colorScheme) {
    return SwitchListTile(
      title: Text(
        "Use Custom Palette",
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        "Enable custom color palettes",
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      value: _localSettings.useCustomPalette,
      onChanged: (value) => _updateSetting('useCustomPalette', value),
      activeColor: Colors.orange,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _PaletteCreationDialog extends StatefulWidget {
  final List<Color> initialColors;

  const _PaletteCreationDialog({required this.initialColors});

  @override
  State<_PaletteCreationDialog> createState() => _PaletteCreationDialogState();
}

class _PaletteCreationDialogState extends State<_PaletteCreationDialog> {
  late TextEditingController _nameController;
  List<Color> _selectedColors = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedColors = List.from(widget.initialColors);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Create New Palette",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Palette Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ColorPickerComponent(
              selectedColors: _selectedColors,
              onColorsChanged: (colors) {
                setState(() {
                  _selectedColors = colors;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty && _selectedColors.isNotEmpty) {
                        Navigator.pop(context, {
                          'name': name,
                          'colors': _selectedColors,
                        });
                      }
                    },
                    child: const Text("Create"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
