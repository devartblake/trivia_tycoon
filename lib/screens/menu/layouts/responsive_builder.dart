import 'package:flutter/material.dart';
import '../../../core/helpers/menu_helpers.dart';
import '../../../game/models/menu_enums.dart';
import 'mobile_layout.dart';
import 'desktop_layout.dart';

/// Responsive builder that chooses layout based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutMode = MenuHelpers.getLayoutMode(width);

        switch (layoutMode) {
          case LayoutMode.desktop:
            return desktop;
          case LayoutMode.tablet:
            return tablet ?? desktop;
          case LayoutMode.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Adaptive layout builder that automatically organizes components
class AdaptiveLayoutBuilder extends StatelessWidget {
  final List<Widget> components;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final double mobileBreakpoint;
  final double tabletBreakpoint;
  final double desktopMaxWidth;

  const AdaptiveLayoutBuilder({
    super.key,
    required this.components,
    this.padding,
    this.physics,
    this.mobileBreakpoint = 768,
    this.tabletBreakpoint = 1024,
    this.desktopMaxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Mobile layout
        if (width < mobileBreakpoint) {
          return MobileLayout(
            components: components,
            padding: padding,
            physics: physics,
          );
        }

        // Tablet layout (2 columns)
        if (width < tabletBreakpoint) {
          return DesktopLayoutBuilder(
            components: components,
            useThreeColumns: false,
            padding: padding,
            physics: physics,
            maxWidth: desktopMaxWidth,
          );
        }

        // Desktop layout (2 or 3 columns based on width)
        final useThreeColumns = width > 1200;
        return DesktopLayoutBuilder(
          components: components,
          useThreeColumns: useThreeColumns,
          padding: padding,
          physics: physics,
          maxWidth: desktopMaxWidth,
        );
      },
    );
  }
}

/// Responsive value based on screen width
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  T getValue(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final layoutMode = MenuHelpers.getLayoutMode(width);

    switch (layoutMode) {
      case LayoutMode.desktop:
        return desktop;
      case LayoutMode.tablet:
        return tablet ?? desktop;
      case LayoutMode.mobile:
        return mobile;
    }
  }
}

/// Responsive padding helper
class ResponsivePadding {
  static EdgeInsets get(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final layoutMode = MenuHelpers.getLayoutMode(width);

    switch (layoutMode) {
      case LayoutMode.desktop:
        return const EdgeInsets.all(32);
      case LayoutMode.tablet:
        return const EdgeInsets.all(24);
      case LayoutMode.mobile:
        return const EdgeInsets.all(20);
    }
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    final width = MediaQuery.of(context).size.width;
    final layoutMode = MenuHelpers.getLayoutMode(width);

    switch (layoutMode) {
      case LayoutMode.desktop:
        return EdgeInsets.symmetric(
          horizontal: horizontal ?? 32,
          vertical: vertical ?? 32,
        );
      case LayoutMode.tablet:
        return EdgeInsets.symmetric(
          horizontal: horizontal ?? 24,
          vertical: vertical ?? 24,
        );
      case LayoutMode.mobile:
        return EdgeInsets.symmetric(
          horizontal: horizontal ?? 20,
          vertical: vertical ?? 20,
        );
    }
  }
}

/// Responsive spacing helper
class ResponsiveSpacing {
  static double get(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final layoutMode = MenuHelpers.getLayoutMode(width);

    switch (layoutMode) {
      case LayoutMode.desktop:
        return 24;
      case LayoutMode.tablet:
        return 20;
      case LayoutMode.mobile:
        return 16;
    }
  }

  static SizedBox box(BuildContext context) {
    return SizedBox(height: get(context));
  }
}

/// Check if current layout is mobile
bool isMobileLayout(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return MenuHelpers.getLayoutMode(width) == LayoutMode.mobile;
}

/// Check if current layout is tablet
bool isTabletLayout(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return MenuHelpers.getLayoutMode(width) == LayoutMode.tablet;
}

/// Check if current layout is desktop
bool isDesktopLayout(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return MenuHelpers.getLayoutMode(width) == LayoutMode.desktop;
}
