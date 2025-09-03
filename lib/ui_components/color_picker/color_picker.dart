import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/services/theme/swatch_service.dart';
import 'ui/color_wheel_picker.dart';
import 'ui/color_slider_picker.dart';
import 'ui/color_preview.dart';
import 'ui/color_preset_selector.dart';

/// 🔵 Main Entry Point for Color Picker Functionality
class ColorPicker {
  static Future<Color?> showColorPickerDialog(BuildContext context,
      {Color initialColor = Colors.blue}) async {
    Color selectedColor = initialColor;
    List<Color> customSwatches = await SwatchService.getCustomSwatches();

    return await showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Pick a Color"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.75,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// 🎨 Preview Box
                      ColorPreview(selectedColor: selectedColor),
                      const SizedBox(height: 12),

                      /// 🎨 Preset Swatches
                      ColorPresetSelector(
                        onColorSelected: (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      const SizedBox(height: 12),

                      /// 🔲 Preview Box
                      Container(
                        height: 40,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black26),
                        ),
                      ),

                      /// 🎨 Color Wheel
                      ColorWheelPicker(
                        initialColor: selectedColor,
                        selectedColor: selectedColor,
                        onColorChanged: (color) {
                          setState(() => selectedColor = color);
                        },
                        onColorSelected: (color) {
                          setState(() => selectedColor = color);
                        },
                      ),

                      const SizedBox(height: 8),

                      /// 🎛️ Sliders
                      ColorSliderPicker(
                        color: selectedColor,
                        initialColor: selectedColor,
                        onColorChanged: (color) {
                          setState(() => selectedColor = color);
                        },
                      ),

                      const SizedBox(height: 12),

                      /// 🎯 Preset Swatches
                      Wrap(
                        spacing: 6,
                        children: customSwatches.map((c) {
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = c),
                            child: CircleAvatar(
                              backgroundColor: c,
                              radius: 14,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (!customSwatches.contains(selectedColor)) {
                      customSwatches.add(selectedColor);
                      await SwatchService.setCustomSwatches(customSwatches);
                      setState(() {});
                    }
                  },
                  child: const Text("Save Swatch"),
                ),
                TextButton(
                  onPressed: () async {
                    await SwatchService.resetSwatchesToDefault();
                    customSwatches.clear();
                    setState(() {});
                  },
                  child: const Text("Reset Swatches"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedColor),
                  child: const Text("Select"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
