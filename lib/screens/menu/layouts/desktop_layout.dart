import 'package:flutter/material.dart';

/// Desktop layout for MainMenuScreen
///
/// Multi-column layout optimized for desktop/tablet devices
class DesktopLayout extends StatelessWidget {
  final List<Widget> leftColumn;
  final List<Widget> rightColumn;
  final List<Widget>? centerColumn;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final double maxWidth;

  const DesktopLayout({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
    this.centerColumn,
    this.padding,
    this.physics,
    this.maxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    final hasThreeColumns = centerColumn != null && centerColumn!.isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          physics: physics ?? const BouncingScrollPhysics(),
          padding: padding ?? const EdgeInsets.all(32),
          child: hasThreeColumns
              ? _buildThreeColumnLayout()
              : _buildTwoColumnLayout(),
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column (60%)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildComponentsWithSpacing(leftColumn),
          ),
        ),
        const SizedBox(width: 24),
        // Right column (40%)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildComponentsWithSpacing(rightColumn),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column (40%)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildComponentsWithSpacing(leftColumn),
          ),
        ),
        const SizedBox(width: 24),
        // Center column (35%)
        Expanded(
          flex: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildComponentsWithSpacing(centerColumn!),
          ),
        ),
        const SizedBox(width: 24),
        // Right column (25%)
        Expanded(
          flex: 25,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildComponentsWithSpacing(rightColumn),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildComponentsWithSpacing(List<Widget> components) {
    if (components.isEmpty) return [];

    final List<Widget> spacedComponents = [];
    for (int i = 0; i < components.length; i++) {
      spacedComponents.add(components[i]);
      // Add spacing between components, but not after the last one
      if (i < components.length - 1) {
        spacedComponents.add(const SizedBox(height: 24));
      }
    }
    return spacedComponents;
  }
}

/// Desktop layout builder for flexible column organization
class DesktopLayoutBuilder extends StatelessWidget {
  final List<Widget> components;
  final bool useThreeColumns;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final double maxWidth;

  const DesktopLayoutBuilder({
    super.key,
    required this.components,
    this.useThreeColumns = false,
    this.padding,
    this.physics,
    this.maxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    if (useThreeColumns) {
      return DesktopLayout(
        leftColumn: _getColumnComponents(0, 3),
        centerColumn: _getColumnComponents(1, 3),
        rightColumn: _getColumnComponents(2, 3),
        padding: padding,
        physics: physics,
        maxWidth: maxWidth,
      );
    } else {
      return DesktopLayout(
        leftColumn: _getColumnComponents(0, 2),
        rightColumn: _getColumnComponents(1, 2),
        padding: padding,
        physics: physics,
        maxWidth: maxWidth,
      );
    }
  }

  List<Widget> _getColumnComponents(int columnIndex, int totalColumns) {
    final List<Widget> columnComponents = [];
    for (int i = columnIndex; i < components.length; i += totalColumns) {
      columnComponents.add(components[i]);
    }
    return columnComponents;
  }
}
