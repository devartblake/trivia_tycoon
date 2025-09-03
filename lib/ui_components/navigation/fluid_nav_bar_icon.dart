import 'package:flutter/cupertino.dart';

/// An icon definition used as child by [FluidNavBar]
///
/// See also:
///
///  * [FluidNavBar]

class FluidNavBarIcon {
 
  @deprecated
  final String? iconPath; /// The path of the SVG asset
  final String? svgPath; /// The SVG path
  final IconData? icon; /// The icon data
  final Color? selectedForegroundColor; /// The color used to paint the SVG when the item is active  
  final Color? unselectedForegroundColor; /// The color used to paint the SVG when the item is inactive  
  final Color? backgroundColor; /// The background color of the item
  final String? tooltip; // New property for tooltips

  /// Extra information which can be used in [FluidNavBarItemBuilder]
  final Map<String, dynamic>? extras;

  FluidNavBarIcon({
    this.iconPath,
    this.svgPath,
    this.icon,
    this.selectedForegroundColor,
    this.unselectedForegroundColor,
    this.backgroundColor,
    this.tooltip, // Initialize tooltip
    this.extras,
  })  : assert(iconPath == null || svgPath == null || icon == null, 'Cannot provide both an svgPath and an icon.'),
        assert(iconPath != null || svgPath != null || icon != null, 'An svgPath or an icon must be provided.');
}