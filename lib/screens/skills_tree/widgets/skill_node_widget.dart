import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trivia_tycoon/ui_components/hex_grid/index.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/services/skill_cooldown_service.dart';
import '../../../ui_components/hex_grid/widgets/hexagon.dart';

enum SkillNodeSize { small, medium, large, extraLarge }

class SkillNodeWidget extends StatelessWidget {
  final SkillNode node;
  final bool isUnlocked;
  final bool isSelected;
  final double? radius; // Made optional - will use size preset if not provided
  final SkillNodeSize size;
  final Color? categoryColor;
  final VoidCallback? onTap;

  // Optional hooks you may use elsewhere
  final VoidCallback? onUnlock;
  final VoidCallback? onUse;

  // Optional cooldown integration
  final SkillCooldownService cooldownService;

  /// Optional extras
  final ui.Image? iconImage; // category/node icon
  final HexOrientation
      orientation; // consistent with your grid (pointy-default)
  final double cornerRadius; // rounded hex corners
  final double borderWidth;
  final Color? labelColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const SkillNodeWidget({
    super.key,
    required this.node,
    required this.isUnlocked,
    required this.isSelected,
    this.radius, // Optional - will use size preset if not provided
    this.size = SkillNodeSize.medium, // Default to medium
    required this.categoryColor,
    required this.onTap,
    this.onUnlock,
    this.onUse,
    required this.cooldownService,
    this.iconImage,
    this.orientation = HexOrientation.pointy,
    this.cornerRadius = 8,
    this.borderWidth = 1.5,
    this.labelColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  // Size configuration map
  static const Map<SkillNodeSize, Map<String, double>> _sizeConfig = {
    SkillNodeSize.small: {
      'radius': 25.0,
      'baseFontSize': 8.0,
      'titleFontSize': 10.0,
      'subtitleFontSize': 7.0,
      'iconSize': 12.0,
      'iconSpacing': 2.0,
      'statusSpacing': 1.0,
      'paddingFactor': 0.06,
    },
    SkillNodeSize.medium: {
      'radius': 40.0,
      'baseFontSize': 11.0,
      'titleFontSize': 14.0,
      'subtitleFontSize': 10.0,
      'iconSize': 18.0,
      'iconSpacing': 4.0,
      'statusSpacing': 2.0,
      'paddingFactor': 0.08,
    },
    SkillNodeSize.large: {
      'radius': 55.0,
      'baseFontSize': 14.0,
      'titleFontSize': 18.0,
      'subtitleFontSize': 12.0,
      'iconSize': 24.0,
      'iconSpacing': 6.0,
      'statusSpacing': 3.0,
      'paddingFactor': 0.10,
    },
    SkillNodeSize.extraLarge: {
      'radius': 70.0,
      'baseFontSize': 16.0,
      'titleFontSize': 22.0,
      'subtitleFontSize': 14.0,
      'iconSize': 30.0,
      'iconSpacing': 8.0,
      'statusSpacing': 4.0,
      'paddingFactor': 0.12,
    },
  };

  double get _effectiveRadius => radius ?? _sizeConfig[size]!['radius']!;
  double get _titleFontSize => _sizeConfig[size]!['titleFontSize']!;
  double get _subtitleFontSize => _sizeConfig[size]!['subtitleFontSize']!;
  double get _iconSize => _sizeConfig[size]!['iconSize']!;
  double get _iconSpacing => _sizeConfig[size]!['iconSpacing']!;
  double get _statusSpacing => _sizeConfig[size]!['statusSpacing']!;
  double get _paddingFactor => _sizeConfig[size]!['paddingFactor']!;

  @override
  Widget build(BuildContext context) {
    final base = categoryColor ?? Colors.grey;
    final isAvailable = node.available && !isUnlocked;

    // Fill: pastel category tint, stronger when selected/unlocked
    final fillOpacity =
        isSelected ? 0.22 : (isUnlocked ? 0.18 : 0.10);
    final fillColor = base.withValues(alpha: fillOpacity);

    // Border: amber for available, category-color otherwise
    final borderColor = isAvailable
        ? const Color(0xFFFFB300).withValues(alpha: 0.80)
        : base.withValues(
            alpha: isSelected ? 0.90 : (isUnlocked ? 0.60 : 0.35));
    final effectiveBorderWidth =
        isSelected ? 2.0 : (isAvailable ? 2.5 : borderWidth);

    // Cost number colour
    final costColor = isUnlocked
        ? base.withValues(alpha: 0.55)
        : isSelected
            ? base
            : isAvailable
                ? const Color(0xFFFFB300)
                : base.withValues(alpha: 0.50);

    final costFontSize = _titleFontSize * 1.3;
    final nameFontSize = _titleFontSize * 0.62;

    // Abbreviated title — single line, max 11 chars
    final abbrev = node.title.length > 11
        ? '${node.title.substring(0, 10)}…'
        : node.title;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+${node.cost}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: costFontSize,
            fontWeight: FontWeight.bold,
            color: costColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          abbrev,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: nameFontSize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.70),
            height: 1.0,
          ),
        ),
        if (isUnlocked) ...[
          const SizedBox(height: 3),
          Icon(
            Icons.check,
            color: Colors.greenAccent.withValues(alpha: 0.65),
            size: nameFontSize + 2,
          ),
        ],
      ],
    );

    final badge = cooldownService.isOnCooldown(node.id)
        ? Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: _CooldownBadge(
                remaining: cooldownService.remaining(node.id)!,
                color: base,
              ),
            ),
          )
        : const SizedBox.shrink();

    Widget hexWidget = Stack(
      children: [
        Hexagon(
          radius: _effectiveRadius,
          orientation: orientation,
          cornerRadius: cornerRadius,
          elevation: 0,
          borderWidth: effectiveBorderWidth,
          color: fillColor,
          borderColor: borderColor,
          shadowColor: Colors.transparent,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(_effectiveRadius * _paddingFactor),
            child: Center(child: content),
          ),
        ),
        badge,
      ],
    );

    // Amber pulse for available nodes
    if (isAvailable) {
      hexWidget =
          hexWidget.animate(onPlay: (c) => c.repeat(reverse: true)).custom(
                duration: 1200.ms,
                curve: Curves.easeInOut,
                builder: (_, value, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius + 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300)
                            .withValues(alpha: 0.35 * value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
    }

    // Subtle category glow for selected nodes
    if (isSelected) {
      hexWidget =
          hexWidget.animate(onPlay: (c) => c.repeat(reverse: true)).custom(
                duration: 1500.ms,
                curve: Curves.easeInOut,
                builder: (_, value, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius + 4),
                    boxShadow: [
                      BoxShadow(
                        color: base.withValues(alpha: 0.28 * value),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
    }

    return GestureDetector(
      onTap: onTap,
      child: hexWidget,
    );
  }

  Widget _getStatusIcon(
      bool unlocked, bool isAvailable, Color textColor, double fontSize) {
    return const SizedBox.shrink();
  }

  Color _tint(Color c, double a) => c.withValues(alpha: a);
}

class _CooldownBadge extends StatelessWidget {
  final Duration remaining;
  final Color color;
  const _CooldownBadge({required this.remaining, required this.color});

  @override
  Widget build(BuildContext context) {
    String mmss(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        mmss(remaining),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }
}

// Convenience constructors for common use cases
extension SkillNodeSizes on SkillNodeWidget {
  static SkillNodeWidget small({
    Key? key,
    required SkillNode node,
    required bool isUnlocked,
    required bool isSelected,
    required Color? categoryColor,
    required VoidCallback? onTap,
    required SkillCooldownService cooldownService,
    VoidCallback? onUnlock,
    VoidCallback? onUse,
    ui.Image? iconImage,
    HexOrientation orientation = HexOrientation.pointy,
    double cornerRadius = 8,
    double borderWidth = 1.5,
    Color? labelColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  }) {
    return SkillNodeWidget(
      key: key,
      node: node,
      isUnlocked: isUnlocked,
      isSelected: isSelected,
      size: SkillNodeSize.small,
      categoryColor: categoryColor,
      onTap: onTap,
      cooldownService: cooldownService,
      onUnlock: onUnlock,
      onUse: onUse,
      iconImage: iconImage,
      orientation: orientation,
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      labelColor: labelColor,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    );
  }

  static SkillNodeWidget large({
    Key? key,
    required SkillNode node,
    required bool isUnlocked,
    required bool isSelected,
    required Color? categoryColor,
    required VoidCallback? onTap,
    required SkillCooldownService cooldownService,
    VoidCallback? onUnlock,
    VoidCallback? onUse,
    ui.Image? iconImage,
    HexOrientation orientation = HexOrientation.pointy,
    double cornerRadius = 8,
    double borderWidth = 1.5,
    Color? labelColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  }) {
    return SkillNodeWidget(
      key: key,
      node: node,
      isUnlocked: isUnlocked,
      isSelected: isSelected,
      size: SkillNodeSize.large,
      categoryColor: categoryColor,
      onTap: onTap,
      cooldownService: cooldownService,
      onUnlock: onUnlock,
      onUse: onUse,
      iconImage: iconImage,
      orientation: orientation,
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      labelColor: labelColor,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    );
  }

  static SkillNodeWidget extraLarge({
    Key? key,
    required SkillNode node,
    required bool isUnlocked,
    required bool isSelected,
    required Color? categoryColor,
    required VoidCallback? onTap,
    required SkillCooldownService cooldownService,
    VoidCallback? onUnlock,
    VoidCallback? onUse,
    ui.Image? iconImage,
    HexOrientation orientation = HexOrientation.pointy,
    double cornerRadius = 8,
    double borderWidth = 1.5,
    Color? labelColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  }) {
    return SkillNodeWidget(
      key: key,
      node: node,
      isUnlocked: isUnlocked,
      isSelected: isSelected,
      size: SkillNodeSize.extraLarge,
      categoryColor: categoryColor,
      onTap: onTap,
      cooldownService: cooldownService,
      onUnlock: onUnlock,
      onUse: onUse,
      iconImage: iconImage,
      orientation: orientation,
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      labelColor: labelColor,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    );
  }
}
