import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/core/services/theme/swatch_service.dart';
import 'ui/color_wheel_picker.dart';
import 'ui/color_slider_picker.dart';
import 'ui/color_preview.dart';
import 'ui/color_preset_selector.dart';

/// Modern Color Picker with optimized performance and enhanced UX
class ColorPicker {
  static Future<Color?> showColorPickerDialog(
      BuildContext context, {
        Color initialColor = Colors.blue,
        bool showSwatches = true,
        bool allowCustomSwatches = true,
        String? title,
        List<Color>? customColors,
      }) async {
    return await showDialog<Color>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModernColorPickerDialog(
        initialColor: initialColor,
        showSwatches: showSwatches,
        allowCustomSwatches: allowCustomSwatches,
        title: title,
        customColors: customColors,
      ),
    );
  }
}

class _ModernColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final bool showSwatches;
  final bool allowCustomSwatches;
  final String? title;
  final List<Color>? customColors;

  const _ModernColorPickerDialog({
    required this.initialColor,
    this.showSwatches = true,
    this.allowCustomSwatches = true,
    this.title,
    this.customColors,
  });

  @override
  State<_ModernColorPickerDialog> createState() => _ModernColorPickerDialogState();
}

class _ModernColorPickerDialogState extends State<_ModernColorPickerDialog>
    with TickerProviderStateMixin {
  late Color _selectedColor;
  late TabController _tabController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  List<Color> _customSwatches = [];
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _colorChangeTimer;

  static const Duration _debounceDelay = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;

    _tabController = TabController(length: 2, vsync: this);
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _loadCustomSwatches();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scaleController.dispose();
    _colorChangeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomSwatches() async {
    if (!widget.showSwatches) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final swatches = widget.customColors ?? await SwatchService.getCustomSwatches();
      if (mounted) {
        setState(() {
          _customSwatches = swatches;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom swatches: $e');
      if (mounted) {
        setState(() {
          _customSwatches = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onColorChanged(Color color) {
    if (_selectedColor == color) return;

    setState(() => _selectedColor = color);

    // Debounce rapid color changes
    _colorChangeTimer?.cancel();
    _colorChangeTimer = Timer(_debounceDelay, () {
      HapticFeedback.selectionClick();
    });
  }

  Future<void> _saveCustomSwatch() async {
    if (_isSaving || !widget.allowCustomSwatches) return;

    if (_customSwatches.contains(_selectedColor)) {
      _showMessage('Color already in swatches', isError: false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newSwatches = [..._customSwatches, _selectedColor];
      await SwatchService.setCustomSwatches(newSwatches);

      if (mounted) {
        setState(() {
          _customSwatches = newSwatches;
          _isSaving = false;
        });
        _showMessage('Swatch saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage('Failed to save swatch', isError: true);
      }
    }
  }

  Future<void> _resetSwatches() async {
    if (_isSaving) return;

    final confirmed = await _showConfirmDialog(
      'Reset Swatches',
      'Are you sure you want to reset all custom swatches to default?',
    );

    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      await SwatchService.resetSwatchesToDefault();
      final defaultSwatches = await SwatchService.getCustomSwatches();

      if (mounted) {
        setState(() {
          _customSwatches = defaultSwatches;
          _isSaving = false;
        });
        _showMessage('Swatches reset to default');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage('Failed to reset swatches', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 700,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(colorScheme),

              // Content
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Expanded(child: _buildContent(colorScheme)),

              // Actions
              _buildActions(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedColor.withOpacity(0.1),
            _selectedColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title ?? "Color Picker",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ColorPreview(selectedColor: _selectedColor),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Wheel"),
                Tab(text: "Sliders"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ColorWheelPicker(
                  initialColor: _selectedColor,
                  selectedColor: _selectedColor,
                  onColorChanged: _onColorChanged,
                  onColorSelected: _onColorChanged,
                ),
                ColorSliderPicker(
                  initialColor: _selectedColor,
                  color: _selectedColor,
                  onColorChanged: _onColorChanged,
                ),
              ],
            ),
          ),

          if (widget.showSwatches) ...[
            const SizedBox(height: 16),
            _buildSwatchSection(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildSwatchSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Custom Swatches",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.allowCustomSwatches)
                IconButton(
                  onPressed: _customSwatches.isNotEmpty ? _resetSwatches : null,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: "Reset swatches",
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: _customSwatches.isEmpty
                ? Center(
              child: Text(
                "No custom swatches",
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _customSwatches.length,
              itemBuilder: (context, index) {
                final color = _customSwatches[index];
                final isSelected = color == _selectedColor;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onColorChanged(color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (widget.allowCustomSwatches && widget.showSwatches)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveCustomSwatch,
                icon: _isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.bookmark_add_rounded),
                label: Text(_isSaving ? "Saving..." : "Save Swatch"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (widget.allowCustomSwatches && widget.showSwatches)
            const SizedBox(width: 16),

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
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, _selectedColor);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text("Select"),
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
    );
  }
}
