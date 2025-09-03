import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/theme/swatch_service.dart';
import '../../../game/controllers/theme_settings_controller.dart';
import '../../../game/providers/riverpod_providers.dart';

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsController, ThemeSettings>((ref) {
  final themeService = ref.read(customThemeServiceProvider);
  return ThemeSettingsController(themeService);
});

class ThemeColorPicker extends ConsumerStatefulWidget {
  final bool isPrimary;

  const ThemeColorPicker({super.key, this.isPrimary = true});

  @override
  ConsumerState<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends ConsumerState<ThemeColorPicker> {
  double hue = 200.0;
  double saturation = 1.0;
  double brightness = 1.0;
  Timer? _debounce;

  Color get currentColor =>
      HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();

  @override
  void initState() {
    super.initState();
    _syncFromTheme();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromTheme();
    });
  }

  void _syncFromTheme() {
    final color = widget.isPrimary
        ? ref.read(themeSettingsProvider).primaryColor
        : ref.read(themeSettingsProvider).secondaryColor;

    final hsb = HSVColor.fromColor(color);

    if (hsb.hue != hue || hsb.saturation != saturation || hsb.value != brightness) {
      setState(() {
        hue = hsb.hue;
        saturation = hsb.saturation;
        brightness = hsb.value;
      });
    }
  }

  void _scheduleThemeUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), (){
      final color = currentColor;
      final controller = ref.read(themeSettingsProvider.notifier);
      if (widget.isPrimary) {
        controller.setPrimaryColor(color);
      } else {
        controller.setSecondaryColor(color);
      }
    });
  }

  void _resetToDefault() {
    final fallback = widget.isPrimary ? Colors.blue : Colors.teal;
    final hsb = HSVColor.fromColor(fallback);
    setState(() {
      hue = hsb.hue;
      saturation = hsb.saturation;
      brightness = hsb.value;
    });
    _scheduleThemeUpdate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isPrimary ? "Primary Color" : "Secondary Color";
    final currentColor = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: currentColor.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preview', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
              Icon(Icons.brightness_6, color: Colors.white),
            ],
          ),
        ),

        /// 🎨 Live Preview
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: [
              BoxShadow(
                color: currentColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 3)
              )
            ],
          ),
          height: 60,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preview', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
              Icon(Icons.brightness_6, color: Colors.white),
            ],
          ),
        ),

        /// 🌈 Hue Slider
        _buildSlider(
          label: 'Hue',
          value: hue,
          min: 0,
          max: 360,
          onChanged: (val) => setState(() {
            hue = val;
            _scheduleThemeUpdate();
          }),
          activeColor: Colors.redAccent,
        ),

        /// 💧 Saturation Slider
        _buildSlider(
          label: 'Saturation',
          value: saturation,
          min: 0,
          max: 1,
          onChanged: (val) => setState(() {
            saturation = val;
            _scheduleThemeUpdate();
          }),
          activeColor: Colors.blueAccent,
        ),

        /// 💡 Brightness Slider
        _buildSlider(
          label: 'Lightness',
          value: brightness,
          min: 0,
          max: 1,
          onChanged: (val) => setState(() {
            brightness = val;
            _scheduleThemeUpdate();
          }),
          activeColor: Colors.orangeAccent,
        ),

        const SizedBox(height: 16),

        /// 🎯 Color Values
        Text(
          'Hex: #${currentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          'HSB: (${hue.toStringAsFixed(1)}, ${saturation.toStringAsFixed(2)}, ${brightness.toStringAsFixed(2)})',
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.bookmark_add),
              label: const Text("Save to Swatches"),
              onPressed: () async {
                final swatches = await SwatchService.getCustomSwatches();
                if (!swatches.contains(currentColor)) {
                  swatches.add(currentColor);
                  await SwatchService.setCustomSwatches(swatches);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Saved color to swatches")),
                  );
                }
              },
            ),
            TextButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min == 1) ? 100 : 360,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
          activeColor: activeColor,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
