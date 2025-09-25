import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/depth_card_theme.dart';

class DepthCardThemeSelector extends StatefulWidget {
  final Function(DepthCardTheme) onThemeSelected;
  final String? selectedName;
  final bool showLabels;
  final double itemSize;
  final EdgeInsets? padding;
  final int crossAxisCount;

  const DepthCardThemeSelector({
    super.key,
    required this.onThemeSelected,
    this.selectedName,
    this.showLabels = true,
    this.itemSize = 80.0,
    this.padding,
    this.crossAxisCount = 2, // Default to 2 for consistency
  });

  @override
  State<DepthCardThemeSelector> createState() => _DepthCardThemeSelectorState();
}

class _DepthCardThemeSelectorState extends State<DepthCardThemeSelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _staggerAnimation;
  DepthCardTheme? _hoveredTheme;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectTheme(DepthCardTheme theme) {
    HapticFeedback.selectionClick();
    widget.onThemeSelected(theme);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themes = DepthCardTheme.presets;

    if (themes.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No themes available',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Padding(
          padding: widget.padding ?? const EdgeInsets.all(8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Always 2 buttons per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, // Equal width and height
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = theme.name == widget.selectedName;
              final isHovered = theme == _hoveredTheme;

              // Stagger animation delay
              final delay = index * 0.1;
              final progress = (_staggerAnimation.value - delay).clamp(0.0, 1.0);

              return Transform.scale(
                scale: progress,
                child: Opacity(
                  opacity: progress,
                  child: _buildThemeCard(
                    theme,
                    isSelected,
                    isHovered,
                    colorScheme,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(
      DepthCardTheme theme,
      bool isSelected,
      bool isHovered,
      ColorScheme colorScheme,
      ) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTheme = theme),
      onExit: (_) => setState(() => _hoveredTheme = null),
      child: GestureDetector(
        onTap: () => _selectTheme(theme),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: _getThemeGradient(theme, isSelected, isHovered),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
            boxShadow: [
              if (isSelected || isHovered) ...[
                BoxShadow(
                  color: _getThemeAccentColor(theme).withOpacity(0.4),
                  blurRadius: isSelected ? 20 : 12,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ],
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Theme Icon with colorful background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getThemeAccentColor(theme).withOpacity(0.9),
                        _getThemeAccentColor(theme).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getThemeIcon(theme),
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 12),

                // Theme name - always shown
                Text(
                  theme.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Selection indicator
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 20,
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
                      Icons.check_rounded,
                      color: _getThemeAccentColor(theme),
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient _getThemeGradient(DepthCardTheme theme, bool isSelected, bool isHovered) {
    final accentColor = _getThemeAccentColor(theme);
    final baseOpacity = isSelected ? 1.0 : (isHovered ? 0.9 : 0.8);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentColor.withOpacity(baseOpacity),
        accentColor.withOpacity(baseOpacity * 0.7),
      ],
    );
  }

  Color _getThemeAccentColor(DepthCardTheme theme) {
    // Map theme names to vibrant colors
    final themeName = theme.name.toLowerCase();

    if (themeName.contains('dark') || themeName.contains('night')) {
      return const Color(0xFF2D3748); // Dark gray-blue
    } else if (themeName.contains('light') || themeName.contains('bright')) {
      return const Color(0xFF3182CE); // Bright blue
    } else if (themeName.contains('neon') || themeName.contains('glow')) {
      return const Color(0xFF9F7AEA); // Electric purple
    } else if (themeName.contains('minimal') || themeName.contains('clean')) {
      return const Color(0xFF48BB78); // Clean green
    } else if (themeName.contains('glass') || themeName.contains('transparent')) {
      return const Color(0xFF4FD1C7); // Glass teal
    } else if (themeName.contains('gradient') || themeName.contains('rainbow')) {
      return const Color(0xFFED64A6); // Rainbow pink
    } else if (themeName.contains('shadow') || themeName.contains('depth')) {
      return const Color(0xFF805AD5); // Deep purple
    } else if (themeName.contains('retro') || themeName.contains('vintage')) {
      return const Color(0xFFD69E2E); // Vintage orange
    } else if (themeName.contains('modern') || themeName.contains('future')) {
      return const Color(0xFF38B2AC); // Future cyan
    } else if (themeName.contains('warm')) {
      return const Color(0xFFE53E3E); // Warm red
    } else if (themeName.contains('cool')) {
      return const Color(0xFF3182CE); // Cool blue
    } else {
      // Generate color based on theme name hash for consistency
      final hash = theme.name.hashCode;
      final colors = [
        const Color(0xFF667EEA), // Purple-blue
        const Color(0xFF764BA2), // Purple
        const Color(0xFF667EEA), // Blue-purple
        const Color(0xFFF093FB), // Pink-purple
        const Color(0xFFF5576C), // Pink-red
        const Color(0xFF4FACFE), // Light blue
        const Color(0xFF43E97B), // Green
        const Color(0xFFFA709A), // Pink
      ];
      return colors[hash.abs() % colors.length];
    }
  }

  IconData _getThemeIcon(DepthCardTheme theme) {
    // Map theme names to appropriate icons
    final themeName = theme.name.toLowerCase();

    if (themeName.contains('dark') || themeName.contains('night')) {
      return Icons.dark_mode_rounded;
    } else if (themeName.contains('light') || themeName.contains('bright')) {
      return Icons.light_mode_rounded;
    } else if (themeName.contains('neon') || themeName.contains('glow')) {
      return Icons.auto_awesome_rounded;
    } else if (themeName.contains('minimal') || themeName.contains('clean')) {
      return Icons.circle_outlined;
    } else if (themeName.contains('glass') || themeName.contains('transparent')) {
      return Icons.blur_on_rounded;
    } else if (themeName.contains('gradient') || themeName.contains('rainbow')) {
      return Icons.gradient_rounded;
    } else if (themeName.contains('shadow') || themeName.contains('depth')) {
      return Icons.layers_rounded;
    } else if (themeName.contains('retro') || themeName.contains('vintage')) {
      return Icons.history_rounded;
    } else if (themeName.contains('modern') || themeName.contains('future')) {
      return Icons.rocket_launch_rounded;
    } else {
      return Icons.style_rounded; // Default icon
    }
  }
}

/// Enhanced theme selector with additional features
class DepthCardThemeSelectorEnhanced extends StatelessWidget {
  final Function(DepthCardTheme) onThemeSelected;
  final String? selectedName;
  final bool showPreview;
  final VoidCallback? onCustomizeTheme;

  const DepthCardThemeSelectorEnhanced({
    super.key,
    required this.onThemeSelected,
    this.selectedName,
    this.showPreview = false,
    this.onCustomizeTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with customize button
        Row(
          children: [
            Text(
              'Theme Presets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (onCustomizeTheme != null)
              OutlinedButton.icon(
                onPressed: onCustomizeTheme,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Customize'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Theme selector with 2 buttons per row
        DepthCardThemeSelector(
          onThemeSelected: onThemeSelected,
          selectedName: selectedName,
          crossAxisCount: 2,
        ),

        // Preview section
        if (showPreview && selectedName != null) ...[
          const SizedBox(height: 16),
          _buildThemePreview(context),
        ],
      ],
    );
  }

  Widget _buildThemePreview(BuildContext context) {
    final selectedTheme = DepthCardTheme.presets
        .where((theme) => theme.name == selectedName)
        .firstOrNull;

    if (selectedTheme == null) return const SizedBox();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Theme Preview: ${selectedTheme.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mini preview card
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      selectedTheme.overlayColor.withOpacity(0.8),
                      selectedTheme.shadowColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: selectedTheme.shadowColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.layers_rounded,
                    color: selectedTheme.textColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPropertyRow(
                      'Elevation',
                      '${selectedTheme.elevation.toStringAsFixed(1)}px',
                      colorScheme,
                    ),
                    const SizedBox(height: 4),
                    _buildPropertyRow(
                      'Glow',
                      selectedTheme.glowEnabled ? 'Enabled' : 'Disabled',
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
