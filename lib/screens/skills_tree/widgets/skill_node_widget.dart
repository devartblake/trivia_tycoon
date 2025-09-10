import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  final ui.Image? iconImage;         // category/node icon
  final HexOrientation orientation;   // consistent with your grid (pointy-default)
  final double cornerRadius;          // rounded hex corners
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
  double get _baseFontSize => _sizeConfig[size]!['baseFontSize']!;
  double get _titleFontSize => _sizeConfig[size]!['titleFontSize']!;
  double get _subtitleFontSize => _sizeConfig[size]!['subtitleFontSize']!;
  double get _iconSize => _sizeConfig[size]!['iconSize']!;
  double get _iconSpacing => _sizeConfig[size]!['iconSpacing']!;
  double get _statusSpacing => _sizeConfig[size]!['statusSpacing']!;
  double get _paddingFactor => _sizeConfig[size]!['paddingFactor']!;

  @override
  Widget build(BuildContext context) {
    final base = categoryColor;
    final bg = _tint(base!, 0.12);       // subtle fill
    final border = _tint(base, 0.30);   // border
    final glow = _tint(base, 0.55);     // selected/unlocked glow
    final textColor = labelColor ?? Colors.white;

    // Elevation/glow rules
    final elevation = isSelected ? 8.0 : (isUnlocked ? 5.0 : 2.0);

    // Content with flexible sizing
    final title = Flexible(
      flex: 2,
      child: Text(
        node.title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: (titleStyle ??
            TextStyle(fontSize: _titleFontSize, fontWeight: FontWeight.w600))
            .copyWith(color: textColor),
      ),
    );

    // Create status widget with icon instead of text
    final statusIcon = _getStatusIcon(node.unlocked, textColor, _subtitleFontSize);

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

    final mainIcon = iconImage == null
        ? Icon(Icons.auto_awesome,
        color: textColor.withOpacity(0.85),
        size: _iconSize)
        : RawImage(
        image: iconImage,
        width: _iconSize,
        height: _iconSize,
        fit: BoxFit.contain);

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // Important: Don't expand beyond needed space
      children: [
        mainIcon,
        SizedBox(height: _iconSpacing),
        title,
        SizedBox(height: _statusSpacing),
        statusIcon,
      ],
    );

    // Create gradient for selected/unlocked states
    final gradient = isSelected || isUnlocked
        ? LinearGradient(
      colors: [
        bg,
        glow.withOpacity(0.2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Hexagon background
          Hexagon(
            radius: _effectiveRadius,
            orientation: orientation,
            cornerRadius: cornerRadius,
            elevation: elevation,
            borderWidth: borderWidth,
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderColor: border,
            shadowColor: isSelected || isUnlocked
                ? glow.withOpacity(0.35)
                : const Color(0x33000000),
            onTap: onTap,
            child: Padding(
              // Size-appropriate padding
              padding: EdgeInsets.all(_effectiveRadius * _paddingFactor),
              child: Center(child: body),
            ),
          ),
          // Cooldown badge overlay if any
          badge,
        ],
      ),
    );
  }

  Widget _getStatusIcon(bool unlocked, Color textColor, double fontSize) {
    if (unlocked) {
      return Icon(
        Icons.check_circle,
        color: Colors.green.withOpacity(0.8),
        size: fontSize + 4,
      );
    } else {
      return Icon(
        Icons.lock,
        color: textColor.withOpacity(0.6),
        size: fontSize + 2,
      );
    }
  }

  Color _tint(Color c, double a) => c.withOpacity(a);
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
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