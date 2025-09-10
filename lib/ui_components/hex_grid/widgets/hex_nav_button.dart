import 'package:flutter/material.dart';
import '../math/hex_orientation.dart';
import '../widgets/hexagon.dart';

enum HexButtonSize { small, medium, large, extraLarge }

class HexNavButton extends StatelessWidget {
  final double? radius; // Made optional - will be overridden by size preset
  final HexButtonSize size;
  final HexOrientation orientation;
  final VoidCallback? onPressed;
  final Widget? icon;
  final String? label;
  final Gradient? gradient;
  final Color borderColor;
  final double? borderWidth; // Made optional - will be sized based on preset
  final bool selected;
  final int? badgeCount;

  const HexNavButton({
    super.key,
    this.radius, // Optional - will use size preset if not provided
    this.size = HexButtonSize.medium, // Default to medium
    this.orientation = HexOrientation.pointy,
    this.onPressed,
    this.icon,
    this.label,
    this.gradient,
    this.borderColor = const Color(0x66FFFFFF),
    this.borderWidth, // Optional - will use size preset if not provided
    this.selected = false,
    this.badgeCount,
  });

  // Size configuration map
  static const Map<HexButtonSize, Map<String, double>> _sizeConfig = {
    HexButtonSize.small: {
      'radius': 16.0,
      'borderWidth': 1.0,
      'iconSize': 12.0,
      'fontSize': 8.0,
      'badgeSize': 8.0,
      'badgePadding': 4.0,
      'badgeOffset': 4.0,
    },
    HexButtonSize.medium: {
      'radius': 22.0,
      'borderWidth': 1.5,
      'iconSize': 16.0,
      'fontSize': 10.0,
      'badgeSize': 10.0,
      'badgePadding': 6.0,
      'badgeOffset': 6.0,
    },
    HexButtonSize.large: {
      'radius': 28.0,
      'borderWidth': 2.0,
      'iconSize': 20.0,
      'fontSize': 12.0,
      'badgeSize': 12.0,
      'badgePadding': 8.0,
      'badgeOffset': 8.0,
    },
    HexButtonSize.extraLarge: {
      'radius': 36.0,
      'borderWidth': 2.5,
      'iconSize': 24.0,
      'fontSize': 14.0,
      'badgeSize': 14.0,
      'badgePadding': 10.0,
      'badgeOffset': 10.0,
    },
  };

  double get _effectiveRadius => radius ?? _sizeConfig[size]!['radius']!;
  double get _effectiveBorderWidth => borderWidth ?? _sizeConfig[size]!['borderWidth']!;
  double get _iconSize => _sizeConfig[size]!['iconSize']!;
  double get _fontSize => _sizeConfig[size]!['fontSize']!;
  double get _badgeSize => _sizeConfig[size]!['badgeSize']!;
  double get _badgePadding => _sizeConfig[size]!['badgePadding']!;
  double get _badgeOffset => _sizeConfig[size]!['badgeOffset']!;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hexagon(
          radius: _effectiveRadius,
          orientation: orientation,
          gradient: gradient ?? LinearGradient(
            colors: selected
                ? const [Color(0xFF2FD5FF), Color(0xFF5B6BFF)]
                : const [Color(0x1AFFFFFF), Color(0x11000000)],
          ),
          borderColor: selected ? Colors.white : borderColor,
          borderWidth: selected ? _effectiveBorderWidth + 0.7 : _effectiveBorderWidth,
          onTap: onPressed,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  IconTheme(
                    data: IconThemeData(size: _iconSize),
                    child: icon!,
                  ),
                if (label != null) ...[
                  SizedBox(height: _fontSize * 0.5), // Proportional spacing
                  Text(
                    label!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            right: -_badgeOffset,
            top: -_badgeOffset,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _badgePadding,
                vertical: _badgePadding * 0.3,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(_badgeSize),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _badgeSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Convenience constructors for common use cases
extension HexNavButtonSizes on HexNavButton {
  static HexNavButton small({
    Key? key,
    HexOrientation orientation = HexOrientation.pointy,
    VoidCallback? onPressed,
    Widget? icon,
    String? label,
    Gradient? gradient,
    Color borderColor = const Color(0x66FFFFFF),
    bool selected = false,
    int? badgeCount,
  }) {
    return HexNavButton(
      key: key,
      size: HexButtonSize.small,
      orientation: orientation,
      onPressed: onPressed,
      icon: icon,
      label: label,
      gradient: gradient,
      borderColor: borderColor,
      selected: selected,
      badgeCount: badgeCount,
    );
  }

  static HexNavButton large({
    Key? key,
    HexOrientation orientation = HexOrientation.pointy,
    VoidCallback? onPressed,
    Widget? icon,
    String? label,
    Gradient? gradient,
    Color borderColor = const Color(0x66FFFFFF),
    bool selected = false,
    int? badgeCount,
  }) {
    return HexNavButton(
      key: key,
      size: HexButtonSize.large,
      orientation: orientation,
      onPressed: onPressed,
      icon: icon,
      label: label,
      gradient: gradient,
      borderColor: borderColor,
      selected: selected,
      badgeCount: badgeCount,
    );
  }

  static HexNavButton extraLarge({
    Key? key,
    HexOrientation orientation = HexOrientation.pointy,
    VoidCallback? onPressed,
    Widget? icon,
    String? label,
    Gradient? gradient,
    Color borderColor = const Color(0x66FFFFFF),
    bool selected = false,
    int? badgeCount,
  }) {
    return HexNavButton(
      key: key,
      size: HexButtonSize.extraLarge,
      orientation: orientation,
      onPressed: onPressed,
      icon: icon,
      label: label,
      gradient: gradient,
      borderColor: borderColor,
      selected: selected,
      badgeCount: badgeCount,
    );
  }
}