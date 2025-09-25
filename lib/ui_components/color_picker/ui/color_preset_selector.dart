import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../presets/color_presets.dart';

class ColorPresetSelector extends StatefulWidget {
  final Function(Color) onColorSelected;

  const ColorPresetSelector({super.key, required this.onColorSelected});

  @override
  State<ColorPresetSelector> createState() => _ColorPresetSelectorState();
}

class _ColorPresetSelectorState extends State<ColorPresetSelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectColor(Color color) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedColor = color;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onColorSelected(color);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: ColorPresets.defaultColors.length,
        itemBuilder: (context, index) {
          final color = ColorPresets.defaultColors[index];
          final isSelected = _selectedColor == color;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => _selectColor(color),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? _scaleAnimation.value : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: isSelected ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                          if (isSelected)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Gradient overlay for depth
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),

                          // Selection indicator
                          if (isSelected)
                            Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: color,
                                  size: 16,
                                  weight: 700,
                                ),
                              ),
                            ),

                          // Ripple effect overlay
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectColor(color),
                              customBorder: const CircleBorder(),
                              splashColor: Colors.white.withOpacity(0.3),
                              highlightColor: Colors.white.withOpacity(0.1),
                              child: Container(
                                width: 64,
                                height: 64,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
