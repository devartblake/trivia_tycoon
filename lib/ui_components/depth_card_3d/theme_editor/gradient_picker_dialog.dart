import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern gradient picker dialog with performance optimizations
class GradientPickerDialog extends StatefulWidget {
  final Gradient? initialGradient;
  final String? title;
  final bool allowCustomColors;
  final List<Color>? predefinedColors;

  const GradientPickerDialog({
    super.key,
    this.initialGradient,
    this.title,
    this.allowCustomColors = true,
    this.predefinedColors,
  });

  static Future<Gradient?> show(
      BuildContext context, {
        Gradient? initialGradient,
        String? title,
        bool allowCustomColors = true,
        List<Color>? predefinedColors,
      }) async {
    return await showDialog<Gradient>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GradientPickerDialog(
        initialGradient: initialGradient,
        title: title,
        allowCustomColors: allowCustomColors,
        predefinedColors: predefinedColors,
      ),
    );
  }

  @override
  State<GradientPickerDialog> createState() => _GradientPickerDialogState();
}

class _GradientPickerDialogState extends State<GradientPickerDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Gradient state
  GradientType _gradientType = GradientType.linear;
  List<GradientStop> _stops = [];
  int _selectedStopIndex = 0;
  AlignmentGeometry _beginAlignment = Alignment.centerLeft;
  AlignmentGeometry _endAlignment = Alignment.centerRight;
  double _centerX = 0.5;
  double _centerY = 0.5;
  double _radius = 0.5;

  // Performance optimization
  Timer? _updateTimer;
  bool _isUpdating = false;
  static const Duration _updateDelay = Duration(milliseconds: 50);

  // Predefined gradients for quick selection
  static final List<Gradient> _presetGradients = [
    LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400]),
    LinearGradient(colors: [Colors.pink.shade400, Colors.orange.shade400]),
    LinearGradient(colors: [Colors.teal.shade400, Colors.green.shade400]),
    LinearGradient(colors: [Colors.red.shade400, Colors.pink.shade400]),
    LinearGradient(colors: [Colors.indigo.shade400, Colors.cyan.shade400]),
    LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade400]),
    RadialGradient(colors: [Colors.purple.shade300, Colors.blue.shade600]),
    LinearGradient(
      colors: [Colors.pink.shade300, Colors.purple.shade400, Colors.blue.shade500],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _initializeGradient();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scaleController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeGradient() {
    if (widget.initialGradient != null) {
      _parseGradient(widget.initialGradient!);
    } else {
      _stops = [
        GradientStop(0.0, Colors.blue.shade400),
        GradientStop(1.0, Colors.purple.shade400),
      ];
    }
  }

  void _parseGradient(Gradient gradient) {
    if (gradient is LinearGradient) {
      _gradientType = GradientType.linear;
      _beginAlignment = gradient.begin;
      _endAlignment = gradient.end;
      _parseColors(gradient.colors, gradient.stops);
    } else if (gradient is RadialGradient) {
      _gradientType = GradientType.radial;
      _centerX = (gradient.center as Alignment).x;
      _centerY = (gradient.center as Alignment).y;
      _radius = gradient.radius;
      _parseColors(gradient.colors, gradient.stops);
    } else if (gradient is SweepGradient) {
      _gradientType = GradientType.sweep;
      _centerX = (gradient.center as Alignment).x;
      _centerY = (gradient.center as Alignment).y;
      _parseColors(gradient.colors, gradient.stops);
    }
  }

  void _parseColors(List<Color> colors, List<double>? stops) {
    _stops.clear();
    for (int i = 0; i < colors.length; i++) {
      final stop = stops?[i] ?? (i / (colors.length - 1));
      _stops.add(GradientStop(stop, colors[i]));
    }
    _stops.sort((a, b) => a.position.compareTo(b.position));
  }

  void _updateGradient() {
    if (_isUpdating) return;

    _updateTimer?.cancel();
    _updateTimer = Timer(_updateDelay, () {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    });

    _isUpdating = true;
  }

  Gradient get _currentGradient {
    final colors = _stops.map((s) => s.color).toList();
    final stops = _stops.map((s) => s.position).toList();

    switch (_gradientType) {
      case GradientType.linear:
        return LinearGradient(
          begin: _beginAlignment,
          end: _endAlignment,
          colors: colors,
          stops: stops,
        );
      case GradientType.radial:
        return RadialGradient(
          center: Alignment(_centerX, _centerY),
          radius: _radius,
          colors: colors,
          stops: stops,
        );
      case GradientType.sweep:
        return SweepGradient(
          center: Alignment(_centerX, _centerY),
          colors: colors,
          stops: stops,
        );
    }
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
            maxWidth: 600,
            maxHeight: 700,
          ),
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
              _buildHeader(colorScheme),
              Expanded(child: _buildContent(colorScheme)),
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
        gradient: _currentGradient,
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gradient_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title ?? "Gradient Picker",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGradientPreview(),
        ],
      ),
    );
  }

  Widget _buildGradientPreview() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        gradient: _currentGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Gradient stops indicators
          ..._stops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isSelected = index == _selectedStopIndex;

            return Positioned(
              left: stop.position * (double.infinity - 24) + 12,
              bottom: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStopIndex = index;
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: stop.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black.withOpacity(0.3),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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
                Tab(text: "Presets"),
                Tab(text: "Colors"),
                Tab(text: "Settings"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildColorsTab(colorScheme),
                _buildSettingsTab(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _presetGradients.length,
      itemBuilder: (context, index) {
        final gradient = _presetGradients[index];

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _parseGradient(gradient);
            _updateGradient();
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                "Preset ${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorsTab(ColorScheme colorScheme) {
    return Column(
      children: [
        // Color stops list
        Expanded(
          child: ListView.builder(
            itemCount: _stops.length,
            itemBuilder: (context, index) {
              final stop = _stops[index];
              final isSelected = index == _selectedStopIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.surfaceContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Color indicator
                    GestureDetector(
                      onTap: () => _pickColorForStop(index),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: stop.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Position slider
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Position: ${(stop.position * 100).toInt()}%",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Slider(
                            value: stop.position,
                            onChanged: (value) {
                              setState(() {
                                _stops[index] = GradientStop(value, stop.color);
                                _selectedStopIndex = index;
                              });
                              _updateGradient();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Remove button
                    if (_stops.length > 2)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _stops.removeAt(index);
                            _selectedStopIndex = (_selectedStopIndex >= _stops.length)
                                ? _stops.length - 1
                                : _selectedStopIndex;
                          });
                          _updateGradient();
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red.shade400,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Add color stop button
        FilledButton.icon(
          onPressed: _addColorStop,
          icon: const Icon(Icons.add),
          label: const Text("Add Color Stop"),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient type selector
          Text(
            "Gradient Type",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          SegmentedButton<GradientType>(
            segments: const [
              ButtonSegment(
                value: GradientType.linear,
                label: Text("Linear"),
                icon: Icon(Icons.linear_scale),
              ),
              ButtonSegment(
                value: GradientType.radial,
                label: Text("Radial"),
                icon: Icon(Icons.radio_button_unchecked),
              ),
              ButtonSegment(
                value: GradientType.sweep,
                label: Text("Sweep"),
                icon: Icon(Icons.refresh),
              ),
            ],
            selected: {_gradientType},
            onSelectionChanged: (Set<GradientType> newSelection) {
              setState(() {
                _gradientType = newSelection.first;
              });
              _updateGradient();
            },
          ),

          const SizedBox(height: 24),

          // Type-specific settings
          if (_gradientType == GradientType.linear) ...[
            _buildLinearSettings(colorScheme),
          ] else if (_gradientType == GradientType.radial) ...[
            _buildRadialSettings(colorScheme),
          ] else if (_gradientType == GradientType.sweep) ...[
            _buildSweepSettings(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildLinearSettings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Linear Direction",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDirectionButton("→", Alignment.centerLeft, Alignment.centerRight),
            _buildDirectionButton("↓", Alignment.topCenter, Alignment.bottomCenter),
            _buildDirectionButton("↗", Alignment.bottomLeft, Alignment.topRight),
            _buildDirectionButton("↘", Alignment.topLeft, Alignment.bottomRight),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionButton(String label, AlignmentGeometry begin, AlignmentGeometry end) {
    final isSelected = _beginAlignment == begin && _endAlignment == end;

    return GestureDetector(
      onTap: () {
        setState(() {
          _beginAlignment = begin;
          _endAlignment = end;
        });
        _updateGradient();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400])
              : null,
          color: isSelected ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadialSettings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Center Position",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("X: ${(_centerX * 100).toInt()}%"),
                  Slider(
                    value: _centerX,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _centerX = value;
                      });
                      _updateGradient();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Y: ${(_centerY * 100).toInt()}%"),
                  Slider(
                    value: _centerY,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _centerY = value;
                      });
                      _updateGradient();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text("Radius: ${(_radius * 100).toInt()}%"),
        Slider(
          value: _radius,
          min: 0.1,
          max: 2.0,
          onChanged: (value) {
            setState(() {
              _radius = value;
            });
            _updateGradient();
          },
        ),
      ],
    );
  }

  Widget _buildSweepSettings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Center Position",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("X: ${(_centerX * 100).toInt()}%"),
                  Slider(
                    value: _centerX,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _centerX = value;
                      });
                      _updateGradient();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Y: ${(_centerY * 100).toInt()}%"),
                  Slider(
                    value: _centerY,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _centerY = value;
                      });
                      _updateGradient();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(ColorScheme colorScheme) {
    return Container(
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
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, _currentGradient);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text("Apply"),
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

  void _addColorStop() {
    setState(() {
      final newPosition = _stops.length > 1
          ? (_stops[_stops.length - 2].position + _stops.last.position) / 2
          : 0.5;
      _stops.add(GradientStop(newPosition, Colors.blue.shade400));
      _stops.sort((a, b) => a.position.compareTo(b.position));
      _selectedStopIndex = _stops.length - 1;
    });
    _updateGradient();
  }

  void _pickColorForStop(int index) async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColor: _stops[index].color,
      ),
    );

    if (selectedColor != null) {
      setState(() {
        _stops[index] = GradientStop(_stops[index].position, selectedColor);
      });
      _updateGradient();
    }
  }
}

// Supporting classes and enums
enum GradientType { linear, radial, sweep }

class GradientStop {
  final double position;
  final Color color;

  GradientStop(this.position, this.color);
}

// Simple color picker dialog
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pick Color"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.red, Colors.pink, Colors.purple, Colors.blue,
              Colors.cyan, Colors.teal, Colors.green, Colors.yellow,
              Colors.orange, Colors.brown, Colors.grey, Colors.black,
            ].map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text("Select"),
        ),
      ],
    );
  }
}
