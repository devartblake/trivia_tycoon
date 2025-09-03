import 'package:flutter/material.dart';

class AvatarShape {
  late double width;
  late double height;
  late RoundedRectangleBorder shapeBorder;

  static AvatarShape circle(double radius) => AvatarShape(
      width: radius * 2,
      height: radius * 2,
      shapeBorder:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)));

  static AvatarShape rectangle(double width, double height,
          [BorderRadius borderRadius = BorderRadius.zero]) =>
      AvatarShape(
          width: width,
          height: height,
          shapeBorder: RoundedRectangleBorder(borderRadius: borderRadius));

  AvatarShape(
      {required this.width, required this.height, required this.shapeBorder});
}
