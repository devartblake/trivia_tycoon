import 'package:flutter/widgets.dart';

/// Slot widgets that can be injected into a DepthCard without changing the
/// JSON-safe spec. This remains UI-only.
///
/// These are used by DepthCardConfig and can be populated by screens/widgets
/// (e.g., badges, buttons, chips, etc.).
class DepthCardSlots {
  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;
  final Widget? center;

  const DepthCardSlots({
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.center,
  });

  static const empty = DepthCardSlots();

  DepthCardSlots copyWith({
    Widget? topLeft,
    Widget? topRight,
    Widget? bottomLeft,
    Widget? bottomRight,
    Widget? center,
  }) {
    return DepthCardSlots(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      center: center ?? this.center,
    );
  }
}
