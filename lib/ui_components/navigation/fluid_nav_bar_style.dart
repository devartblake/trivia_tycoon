import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// An immutable style in which paint [FluidNavBar]
///
///
/// {@tool sample}
/// Here, a [FluidNavBar] with a given specific style which overrides the default color style of the background
///
/// ```dart
/// FluidNavBar(
///   icons: [
///     FluidNavBarIcon(iconPath: "assets/home.svg"),
///     FluidNavBarIcon(iconPath: "assets/bookmark.svg"),
///   ],
///   style: FluidNavBarStyle(
///     backgroundColor: Colors.red,
/// )
/// ```
/// {@end-tool}
@immutable
class FluidNavBarStyle with Diagnosticable {  
  final Color? barBackgroundColor;  /// The navigation bar background color  
  final Color? iconBackgroundColor; /// Icons background color  
  final Color? iconSelectedForegroundColor; /// Icons color when activated  
  final Color? iconUnselectedForegroundColor; /// Icons color when inactivated

  // New properties
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const FluidNavBarStyle({
    this.barBackgroundColor,
    this.iconBackgroundColor,
    this.iconSelectedForegroundColor,
    this.iconUnselectedForegroundColor,
    this.borderRadius, // Optional border radius
    this.boxShadow,    // Optional shadows
  });

}