import 'package:flutter/material.dart';
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
  _ColorPickerScreenState createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  late ColorPickerController _controller;
  late ColorPerformance _performanceTracker;
  List<Color> savedColors = [];
  String _fpsCategory = "High";
  ColorPickerTheme _colorPickerTheme = ColorPickerTheme.light;

  ColorPickerTheme get colorPickerTheme => _colorPickerTheme;

  @override
  void initState() {
    super.initState();
    _controller = ColorPickerController();
    _performanceTracker = ColorPerformance();
    _performanceTracker.startTracking(onUpdated: () {
      setState(() {
        _fpsCategory = _performanceTracker.getPerformanceCategory();
      });
    });
    _loadSavedColors();
    _loadTheme();
  }

  // **🔄 Load saved theme from storage**
  void _loadTheme() async {
    Map<String, dynamic>? themeMap = await ColorStorage.getPickerTheme();
    if (themeMap != null && themeMap.isNotEmpty) {
      setState(() {
        _colorPickerTheme = ColorPickerTheme.fromMap(themeMap);
      });
    }
  }

  /// **📥 Load saved colors**
  void _loadSavedColors() async {
    List<Color> colors = await ColorStorage.loadSavedColors();
    setState(() {
      savedColors = colors;
    });
  }

  @override
  void dispose() {
    _performanceTracker.stopTracking();
    super.dispose();
  }

  /// **📤 Export logs**
  void _exportLogs() async {
    String path = await ColorLogManager.exportLogs();

    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logs exported: $path")),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Color Picker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => ColorStorage.saveColor(_controller.selectedColor),
          ),
          IconButton(
              onPressed: _exportLogs,
              icon: const Icon(Icons.file_download)
          ),
        ],
      ),
      body: Stack (
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// **🎨 Color Preview**
                ColorPreview(selectedColor: _controller.selectedColor),

                const SizedBox(height: 10),

                /// **🌈 Preset Color Selector**
                ColorPresetSelector(
                  onColorSelected: (color) {
                    setState(() {
                      _controller.updateColor(color);
                      ColorLogManager.logColorSelection(color.value.toRadixString(16).toUpperCase());
                    });
                  },
                ),

                const SizedBox(height: 10),

                /// **🎛️ Color Sliders for fine-tuning**
                ColorSliderPicker(
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
                ),

                const SizedBox(height: 10),

                /// **🎡 Color Wheel Picker**
                ColorWheelPicker(
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


                const SizedBox(height: 10),

                /// **💾 Save Button**
                ColorSaveButton(
                  selectedColor: _controller.selectedColor,
                  onSaved: () {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 10),

                /// **📊 Performance Debug Overlay**
                ColorDebugOverlay(selectedColor: _controller.selectedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
