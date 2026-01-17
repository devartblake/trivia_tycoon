import 'package:flutter/material.dart';

/// Modern avatar shape utility with extended shape options
class AvatarShape {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;
  final BoxShape boxShape;

  const AvatarShape._({
    required this.width,
    required this.height,
    required this.shapeBorder,
    required this.boxShape,
  });

  /// Perfect circle avatar
  static AvatarShape circle(double radius) => AvatarShape._(
    width: radius * 2,
    height: radius * 2,
    shapeBorder: const CircleBorder(),
    boxShape: BoxShape.circle,
  );

  /// Rounded rectangle avatar
  static AvatarShape rectangle(
      double width,
      double height, [
        BorderRadius borderRadius = BorderRadius.zero,
      ]) =>
      AvatarShape._(
        width: width,
        height: height,
        shapeBorder: RoundedRectangleBorder(borderRadius: borderRadius),
        boxShape: BoxShape.rectangle,
      );

  /// Squircle (super-ellipse) for modern iOS-style avatars
  static AvatarShape squircle(double size, {double smoothness = 0.6}) =>
      AvatarShape._(
        width: size,
        height: size,
        shapeBorder: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(size * smoothness),
        ),
        boxShape: BoxShape.rectangle,
      );

  /// Rounded square with consistent corner radius
  static AvatarShape roundedSquare(double size, {double cornerRadius = 12.0}) =>
      AvatarShape._(
        width: size,
        height: size,
        shapeBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        boxShape: BoxShape.rectangle,
      );

  /// Stadium (pill shape) for horizontal avatars
  static AvatarShape stadium(double width, double height) => AvatarShape._(
    width: width,
    height: height,
    shapeBorder: const StadiumBorder(),
    boxShape: BoxShape.rectangle,
  );

  /// Custom shape with specified shape border
  static AvatarShape custom({
    required double width,
    required double height,
    required ShapeBorder shape,
    BoxShape boxShape = BoxShape.rectangle,
  }) =>
      AvatarShape._(
        width: width,
        height: height,
        shapeBorder: shape,
        boxShape: boxShape,
      );
}