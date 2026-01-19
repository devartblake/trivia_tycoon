import 'package:flutter/material.dart';

/// Mobile layout for MainMenuScreen
///
/// Single column layout optimized for mobile devices
class MobileLayout extends StatelessWidget {
  final List<Widget> components;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const MobileLayout({
    super.key,
    required this.components,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildComponentsWithSpacing(),
      ),
    );
  }

  List<Widget> _buildComponentsWithSpacing() {
    if (components.isEmpty) return [];

    final List<Widget> spacedComponents = [];
    for (int i = 0; i < components.length; i++) {
      spacedComponents.add(components[i]);
      // Add spacing between components, but not after the last one
      if (i < components.length - 1) {
        spacedComponents.add(const SizedBox(height: 20));
      }
    }
    return spacedComponents;
  }
}
