import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/controllers/theme_settings_controller.dart';

class ThemeSwatchGrid extends ConsumerStatefulWidget {
  const ThemeSwatchGrid({super.key});

  @override
  ConsumerState<ThemeSwatchGrid> createState() => _ThemeSwatchGridState();
}

class _ThemeSwatchGridState extends ConsumerState<ThemeSwatchGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;

  final List<Map<String, dynamic>> _primarySwatches = [
    {'color': const Color(0xFF6366F1), 'name': 'Indigo'},
    {'color': const Color(0xFF8B5CF6), 'name': 'Purple'},
    {'color': const Color(0xFF10B981), 'name': 'Emerald'},
    {'color': const Color(0xFFEF4444), 'name': 'Red'},
    {'color': const Color(0xFFF59E0B), 'name': 'Amber'},
    {'color': const Color(0xFF06B6D4), 'name': 'Cyan'},
    {'color': const Color(0xFFEC4899), 'name': 'Pink'},
    {'color': const Color(0xFF84CC16), 'name': 'Lime'},
    {'color': const Color(0xFF8B5CF6), 'name': 'Violet'},
    {'color': const Color(0xFF06B6D4), 'name': 'Sky'},
  ];

  final List<Map<String, dynamic>> _secondarySwatches = [
    {'color': const Color(0xFF8B5CF6), 'name': 'Purple'},
    {'color': const Color(0xFF10B981), 'name': 'Emerald'},
    {'color': const Color(0xFFEF4444), 'name': 'Red'},
    {'color': const Color(0xFFF59E0B), 'name': 'Amber'},
    {'color': const Color(0xFF06B6D4), 'name': 'Cyan'},
    {'color': const Color(0xFFEC4899), 'name': 'Pink'},
    {'color': const Color(0xFF6366F1), 'name': 'Indigo'},
    {'color': const Color(0xFF84CC16), 'name': 'Lime'},
    {'color': const Color(0xFF0EA5E9), 'name': 'Blue'},
    {'color': const Color(0xFFF97316), 'name': 'Orange'},
  ];

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      _primarySwatches.length + _secondarySwatches.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _animationControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(themeSettingsProvider.notifier);
    final current = ref.watch(themeSettingsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF64748B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Color Swatches', Icons.palette_rounded),
          const SizedBox(height: 24),
          _buildColorSection('Primary Color', _primarySwatches, current.primaryColor, true, controller),
          const SizedBox(height: 32),
          _buildColorSection('Secondary Color', _secondarySwatches, current.secondaryColor, false, controller),
          const SizedBox(height: 32),
          _buildCustomizeButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection(
      String title,
      List<Map<String, dynamic>> swatches,
      Color currentColor,
      bool isPrimary,
      ThemeSettingsController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: swatches.length,
          itemBuilder: (context, index) {
            final swatch = swatches[index];
            final color = swatch['color'] as Color;
            final name = swatch['name'] as String;
            final isSelected = color.value == currentColor.value;
            final animationIndex = isPrimary ? index : index + _primarySwatches.length;

            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _animationControllers[animationIndex],
                curve: Curves.easeOutBack,
              )),
              child: Tooltip(
                message: name,
                child: GestureDetector(
                  onTap: () {
                    if (isPrimary) {
                      controller.setPrimaryColor(color);
                    } else {
                      controller.setSecondaryColor(color);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(isSelected ? 0.4 : 0.2),
                          blurRadius: isSelected ? 12 : 6,
                          offset: Offset(0, isSelected ? 6 : 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isSelected
                          ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomizeButton() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => context.push('/theme-editor'),
          icon: const Icon(Icons.brush_rounded, color: Colors.white),
          label: const Text(
            'Advanced Customization',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}