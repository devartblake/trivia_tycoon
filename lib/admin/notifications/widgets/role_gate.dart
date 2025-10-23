import 'package:flutter/material.dart';

class RoleGate extends StatelessWidget {
  final bool isAllowed;
  final Widget child;
  final Widget? blocked;
  const RoleGate(
      {super.key, required this.isAllowed, required this.child, this.blocked});

  @override
  Widget build(BuildContext context) {
    if (isAllowed) return child;
    return blocked ??
        AbsorbPointer(
          absorbing: true,
          child: Opacity(opacity: 0.5, child: child),
        );
  }
}
