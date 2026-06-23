import 'package:flutter/material.dart';

/// Responsive layout utility for the spin wheel
/// Provides device-aware sizing and layout configuration
class WheelResponsive {
  // Breakpoints for responsive design
  static const int mobileMaxWidth = 600;
  static const int tabletMaxWidth = 900;

  /// Get responsive wheel size based on screen width
  static double getWheelSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > tabletMaxWidth) {
      return 350; // Desktop: larger wheel
    } else if (screenWidth > mobileMaxWidth) {
      return 310; // Tablet: medium wheel
    } else {
      return 280; // Mobile: smaller wheel
    }
  }

  /// Determine if layout should be desktop mode (side-by-side)
  static bool isDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Desktop layout if width > 900 AND height is sufficient
    return screenWidth > tabletMaxWidth && screenHeight > 700;
  }

  /// Determine if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > tabletMaxWidth) {
      return const EdgeInsets.all(32);
    } else if (screenWidth > mobileMaxWidth) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get responsive stat cards layout columns
  static int getStatCardsColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > tabletMaxWidth) {
      return 3; // Desktop: 3 cards in a row
    } else if (screenWidth > mobileMaxWidth) {
      return 3; // Tablet: 3 cards in a row
    } else {
      return 2; // Mobile: 2 cards in a row
    }
  }

  /// Get max width for content container (prevents excessive stretching on ultra-wide)
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1400) {
      return 1200; // Cap at 1200px for ultra-wide screens
    }
    return double.infinity;
  }

  /// Get responsive wheel container margin
  static EdgeInsets getWheelContainerMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > tabletMaxWidth) {
      return const EdgeInsets.all(32);
    } else if (screenWidth > mobileMaxWidth) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > tabletMaxWidth) {
      return 60; // Desktop: larger buttons
    } else if (screenWidth > mobileMaxWidth) {
      return 54; // Tablet: medium buttons
    } else {
      return 48; // Mobile: standard buttons
    }
  }

  /// Get screen size category for debugging/analytics
  static String getSizeName(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > tabletMaxWidth) {
      return 'desktop';
    } else if (screenWidth > mobileMaxWidth) {
      return 'tablet';
    } else {
      return 'mobile';
    }
  }
}
