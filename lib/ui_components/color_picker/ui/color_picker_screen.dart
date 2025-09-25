import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/ui_components/color_picker/core/color_picker_theme.dart';
import 'package:trivia_tycoon/ui_components/color_picker/ui/color_debug_overlay.dart';
import '../../color_picker/utils/color_log_manager.dart';
import '../../color_picker/utils/color_performance.dart';
import '../../color_picker/utils/color_storage.dart';
import '../../color_picker/core/color_picker_controller.dart';
import 'color_preview.dart';
import 'color_save_button.dart';
import 'color_wheel_picker.dart';
import 'color_slider_picker.dart';
import 'color_preset_selector.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen>
    with TickerProviderStateMixin {
  late ColorPickerController _controller;
  late ColorPerformance _performanceTracker;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Color> savedColors = [];
  String _fpsCategory = "High";
  ColorPickerTheme _colorPickerTheme = ColorPickerTheme.light;
  int _selectedTabIndex = 0;

  ColorPickerTheme get colorPickerTheme => _colorPickerTheme;

  @override
  void initState() {
    super.initState();
    _controller = ColorPickerController();
    _performanceTracker = ColorPerformance();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _performanceTracker.startTracking(onUpdated: () {
      if (mounted) {
        setState(() {
          _fpsCategory = _performanceTracker.getPerformanceCategory();
        });
      }
    });

    _loadSavedColors();
    _loadTheme();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _performanceTracker.stopTracking();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadTheme() async {
    try {
      Map<String, dynamic>? themeMap = await ColorStorage.getPickerTheme();
      if (themeMap != null && themeMap.isNotEmpty && mounted) {
        setState(() {
          _colorPickerTheme = ColorPickerTheme.fromMap(themeMap);
        });
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  void _loadSavedColors() async {
    try {
      List<Color> colors = await ColorStorage.loadSavedColors();
      if (mounted) {
        setState(() {
          savedColors = colors;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved colors: $e');
    }
  }

  void _exportLogs() async {
    try {
      HapticFeedback.lightImpact();
      String path = await ColorLogManager.exportLogs();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text("Logs exported to: $path")),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error exporting logs: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _saveCurrentColor() async {
    try {
      HapticFeedback.lightImpact();
      await ColorStorage.saveColor(_controller.selectedColor);
      _loadSavedColors();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text("Color saved successfully!"),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving color: $e"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "Color Studio",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _exportLogs,
              icon: const Icon(Icons.download_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainer,
                foregroundColor: colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _saveCurrentColor,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text("Save"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Color Preview Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _controller.selectedColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.purple.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.palette_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Color Preview",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ColorPreview(selectedColor: _controller.selectedColor),
                      ],
                    ),
                  ),
                ),

                // Color Presets Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink.shade400,
                                    Colors.orange.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.gradient_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Quick Presets",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ColorPresetSelector(
                          onColorSelected: (color) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _controller.updateColor(color);
                              ColorLogManager.logColorSelection(
                                color.value.toRadixString(16).toUpperCase(),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Color Picker Tools Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2D2D44)
                          : const Color(0xFFF5F9FA),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal.shade400,
                                    Colors.green.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Color Tools",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tab Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTabButton(
                                  "Sliders",
                                  Icons.tune_rounded,
                                  0,
                                  colorScheme,
                                ),
                              ),
                              Expanded(
                                child: _buildTabButton(
                                  "Wheel",
                                  Icons.color_lens_rounded,
                                  1,
                                  colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Content based on selected tab
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedTabIndex == 0
                              ? ColorSliderPicker(
                            key: const ValueKey('sliders'),
                            color: _controller.selectedColor,
                            onColorChanged: (color) {
                              setState(() {
                                _controller.updateColor(color);
                                ColorLogManager.logColorSelection(
                                  color.value.toRadixString(16).toUpperCase(),
                                );
                              });
                            },
                            initialColor: _controller.selectedColor,
                          )
                              : ColorWheelPicker(
                            key: const ValueKey('wheel'),
                            selectedColor: _controller.selectedColor,
                            onColorChanged: (color) {
                              setState(() {
                                _controller.updateColor(color);
                                ColorLogManager.logColorSelection(
                                  color.value.toRadixString(16).toUpperCase(),
                                );
                              });
                            },
                            initialColor: _controller.selectedColor,
                            onColorSelected: (color) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: ColorSaveButton(
                      selectedColor: _controller.selectedColor,
                      onSaved: () {
                        _loadSavedColors();
                      },
                    ),
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),

            // Debug Overlay (positioned on top of everything)
            if (!kReleaseMode)
              ColorDebugOverlay(selectedColor: _controller.selectedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
      String title,
      IconData icon,
      int index,
      ColorScheme colorScheme,
      ) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              Colors.teal.shade400,
              Colors.green.shade400,
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}