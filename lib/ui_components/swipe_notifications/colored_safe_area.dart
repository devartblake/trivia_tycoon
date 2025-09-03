import 'package:flutter/material.dart';

class ColoredSafeArea extends StatelessWidget {
  const ColoredSafeArea(
      {super.key,
      this.left = true,
      this.top = true,
      this.right = true,
      this.bottom = true,
      this.minimum,
      required this.child,
      this.color,
      this.gradient});

  //Color properties, gradient takes priority
  final Color? color;
  final Gradient? gradient;

  //Passed through to SafeArea
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets? minimum;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        (gradient != null)
            ? Container(
                decoration: BoxDecoration(gradient: gradient),
              )
            : Container(
                color: color ?? Color(0x00000000),
              ),
        SafeArea(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          minimum: minimum ?? EdgeInsets.all(0),
          child: child,
        )
      ],
    );
  }
}