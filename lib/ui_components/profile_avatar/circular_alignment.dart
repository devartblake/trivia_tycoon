import 'extensions.dart';
import 'profile_avatar_inherited.dart';
import 'package:flutter/widgets.dart';

/// Positions a widget at a specific alignment on a circular boundary
///
/// This widget is used to position badges, status indicators, and other
/// elements around the edge of circular avatars. It uses the parent avatar's
/// radius to calculate the correct offset position.
class AlignCircular extends StatelessWidget {
  const AlignCircular({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
    this.radius = 0.0,
    this.size = Size.zero,
    this.offset = Offset.zero,
  });

  /// The alignment position on the circular boundary
  ///
  /// Examples:
  /// - [Alignment.topRight] - Top right corner
  /// - [Alignment.bottomRight] - Bottom right corner (common for status indicators)
  /// - [Alignment.topCenter] - Top center
  final Alignment alignment;

  /// Parent widget radius (usually provided by [ProfileAvatarInherited])
  final double radius;

  /// The size of the child widget
  ///
  /// This is required for proper gesture detection. Without it, the widget
  /// will be positioned correctly but won't respond to gestures like taps.
  final Size size;

  /// Additional offset to fine-tune the position
  final Offset offset;

  /// The child widget to position
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Get the parent avatar's radius from the inherited widget
    final effectiveRadius =
        ProfileAvatarInherited.of(context)?.radius ?? radius;

    // Calculate the offset based on alignment and radius
    final calculatedOffset = alignment.toOffsetWithRadius(
      radius: effectiveRadius,
    );

    // Apply custom offset if provided
    final finalOffset = calculatedOffset + offset;

    return Positioned(
      width: size.width > 0 ? size.width : null,
      height: size.height > 0 ? size.height : null,
      left: size.width > 0 ? finalOffset.dx - size.width / 2.0 : finalOffset.dx,
      top: size.height > 0 ? finalOffset.dy - size.height / 2.0 : finalOffset.dy,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: child,
      ),
    );
  }
}