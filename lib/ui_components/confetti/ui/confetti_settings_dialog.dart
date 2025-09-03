import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../models/confetti_settings.dart';

class ConfettiSettingsDialog extends ConsumerStatefulWidget {
  final ConfettiSettings initialSettings;
  final Function(ConfettiSettings) onSave;

  const ConfettiSettingsDialog({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  _ConfettiSettingsDialogState createState() => _ConfettiSettingsDialogState();
}

class _ConfettiSettingsDialogState extends ConsumerState<ConfettiSettingsDialog> {
  late ConfettiSettings _settings;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(confettiControllerProvider);
    _settings = controller.currentTheme.toSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Confetti Settings"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSlider(
              label: "Density",
              value: _settings.density,
              min: 10,
              max: 200,
              onChanged: (value) =>
                  setState(() => _settings = _settings.copyWith(density: value)),
            ),
            _buildSlider(
              label: "Speed",
              value: _settings.speed,
              min: 0.1,
              max: 5.0,
              onChanged: (value) =>
                  setState(() => _settings = _settings.copyWith(speed: value)),
            ),
            _buildSwitch(
              "Enable Gravity",
              _settings.enableGravity,
                  (value) => setState(() => _settings = _settings.copyWith(enableGravity: value)),
            ),
            const SizedBox(height: 8),
            _buildSwitch(
              "Enable Rotation",
              _settings.enableRotation,
                  (value) => setState(() => _settings = _settings.copyWith(enableRotation: value)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancel"),
        ),
        TextButton(
           onPressed: () {
             setState(() {
               _settings = ConfettiSettings(); // Reset to defaults
             });
           },
           child: const Text("Reset to Default"),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(confettiControllerProvider.notifier).updateSettings(_settings);
            Navigator.of(context).pop();
          },
          child: Text("Save"),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

