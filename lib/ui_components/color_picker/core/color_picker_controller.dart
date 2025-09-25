import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/color_storage.dart';

class ColorPickerController extends ChangeNotifier {
  Color _selectedColor = Colors.blue;
  bool _useCustomPalette = false;
  List<Color> _customPalette = [];

  // Performance optimizations
  Timer? _saveTimer;
  Color? _lastSavedColor;
  bool _isDisposed = false;

  static const Duration _saveDelay = Duration(milliseconds: 500);

  ColorPickerController() {
    _loadSavedSettings();
  }

  Color get selectedColor => _selectedColor;
  bool get useCustomPalette => _useCustomPalette;
  List<Color> get customPalette => List.unmodifiable(_customPalette);

  @override
  void dispose() {
    _isDisposed = true;
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Load saved settings from local storage with error handling.
  Future<void> _loadSavedSettings() async {
    try {
      final savedColor = await ColorStorage.getSavedColor();
      final customPalette = await ColorStorage.getCustomPalette();

      if (!_isDisposed) {
        _selectedColor = savedColor ?? Colors.blue;
        _customPalette = customPalette ?? [];
        _useCustomPalette = _customPalette.isNotEmpty;
        _lastSavedColor = _selectedColor;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading color picker settings: $e');
      // Use defaults if loading fails
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// Update selected color with debounced saving.
  void updateColor(Color newColor) {
    if (_selectedColor == newColor || _isDisposed) return;

    _selectedColor = newColor;
    notifyListeners();

    // Debounce saving to avoid excessive I/O
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () => _saveColorDebounced(newColor));
  }

  /// Save color with debouncing to prevent excessive file operations.
  Future<void> _saveColorDebounced(Color color) async {
    if (_isDisposed || _lastSavedColor == color) return;

    try {
      await ColorStorage.saveColor(color);
      _lastSavedColor = color;
    } catch (e) {
      debugPrint('Error saving color: $e');
    }
  }

  /// Force immediate save of current color.
  Future<void> saveCurrentColor() async {
    _saveTimer?.cancel();
    await _saveColorDebounced(_selectedColor);
  }

  /// Enable or disable custom color palettes.
  void toggleCustomPalette(bool enabled) {
    if (_useCustomPalette == enabled || _isDisposed) return;

    _useCustomPalette = enabled;
    notifyListeners();
  }

  /// Update custom color palette with validation.
  Future<void> updateCustomPalette(List<Color> palette) async {
    if (_isDisposed) return;

    // Validate palette
    final validPalette = palette.where((color) => color != null).toList();

    if (_customPalette.length == validPalette.length &&
        _customPalette.every((color) => validPalette.contains(color))) {
      return; // No changes needed
    }

    _customPalette = validPalette;
    notifyListeners();

    try {
      await ColorStorage.saveCustomPalette(_customPalette);
    } catch (e) {
      debugPrint('Error saving custom palette: $e');
    }
  }

  /// Add color to custom palette if not already present.
  Future<void> addToCustomPalette(Color color) async {
    if (_isDisposed || _customPalette.contains(color)) return;

    final newPalette = List<Color>.from(_customPalette)..add(color);
    await updateCustomPalette(newPalette);
  }

  /// Remove color from custom palette.
  Future<void> removeFromCustomPalette(Color color) async {
    if (_isDisposed || !_customPalette.contains(color)) return;

    final newPalette = List<Color>.from(_customPalette)..remove(color);
    await updateCustomPalette(newPalette);
  }

  /// Clear all custom palette colors.
  Future<void> clearCustomPalette() async {
    if (_isDisposed || _customPalette.isEmpty) return;

    await updateCustomPalette([]);
  }

  /// Reset to default settings.
  Future<void> reset() async {
    if (_isDisposed) return;

    _saveTimer?.cancel();
    _selectedColor = Colors.blue;
    _useCustomPalette = false;
    _customPalette.clear();
    _lastSavedColor = null;

    notifyListeners();

    try {
      await ColorStorage.saveColor(_selectedColor);
      await ColorStorage.saveCustomPalette([]);
    } catch (e) {
      debugPrint('Error resetting color picker: $e');
    }
  }
}
