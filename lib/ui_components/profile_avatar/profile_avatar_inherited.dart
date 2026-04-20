import 'package:flutter/widgets.dart';

/// Provides avatar radius information to descendant widgets
///
/// This inherited widget allows child widgets (like [AlignCircular]) to access
/// the parent avatar's radius without explicitly passing it through constructors.
/// This is particularly useful for positioning badges and status indicators
/// around the avatar's edge.
class ProfileAvatarInherited extends InheritedWidget {
  const ProfileAvatarInherited({
    super.key,
    required super.child,
    required this.radius,
  });

  /// The radius of the parent avatar
  final double radius;

  /// Retrieves the nearest [ProfileAvatarInherited] ancestor
  ///
  /// Returns null if no ancestor is found in the widget tree.
  static ProfileAvatarInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProfileAvatarInherited>();
  }

  /// Retrieves the radius from the nearest ancestor
  ///
  /// Returns the provided [defaultRadius] if no ancestor is found.
  /// This is a convenience method to avoid null checks.
  static double radiusOf(BuildContext context, {double defaultRadius = 0.0}) {
    return of(context)?.radius ?? defaultRadius;
  }

  @override
  bool updateShouldNotify(ProfileAvatarInherited oldWidget) {
    return oldWidget.radius != radius;
  }
}
