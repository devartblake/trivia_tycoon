import 'package:flutter/material.dart';
import '../utils/color_storage.dart';

class ColorPickerController extends ChangeNotifier {
  Color _selectedColor = Colors.blue;
  bool _useCustomPalette = false;
  List<Color> _customPalette = [];

  ColorPickerController() {
    _loadSavedSettings();
  }

  Color get selectedColor => _selectedColor;
  bool get useCustomPalette => _useCustomPalette;
  List<Color> get customPalette => _customPalette;

  /// Load saved settings from local storage.
  Future<void> _loadSavedSettings() async {
    _selectedColor = await ColorStorage.getSavedColor() ?? Colors.blue;
    _customPalette = await ColorStorage.getCustomPalette() ?? [];
    _useCustomPalette = _customPalette.isNotEmpty;
    notifyListeners();
  }

  /// Update selected color and save it.
  void updateColor(Color newColor) {
    _selectedColor = newColor;
    ColorStorage.saveColor(newColor);
    notifyListeners();
  }

  /// Enable or disable custom color palettes.
  void toggleCustomPalette(bool enabled) {
    _useCustomPalette = enabled;
    notifyListeners();
  }

  /// Save custom color palette.
  void updateCustomPalette(List<Color> palette) {
    _customPalette = palette;
    ColorStorage.saveCustomPalette(palette);
    notifyListeners();
  }
}
