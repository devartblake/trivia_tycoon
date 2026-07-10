import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobile = 640;
  static const double tablet = 640;
  static const double desktop = 1100;
  static const double dashboardRail = 1120;
  static const double wideDesktop = 1400;

  const AppBreakpoints._();

  static AppLayoutClass classify(double width) {
    if (width >= desktop) return AppLayoutClass.desktop;
    if (width >= tablet) return AppLayoutClass.tablet;
    return AppLayoutClass.mobile;
  }
}

enum AppLayoutClass {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == AppLayoutClass.mobile;
  bool get isTablet => this == AppLayoutClass.tablet;
  bool get isDesktop => this == AppLayoutClass.desktop;
}

class AppResponsive {
  const AppResponsive._();

  static AppLayoutClass layoutOf(BuildContext context) {
    return AppBreakpoints.classify(MediaQuery.sizeOf(context).width);
  }

  static EdgeInsets pagePadding(AppLayoutClass layout) {
    return switch (layout) {
      AppLayoutClass.desktop => const EdgeInsets.all(24),
      AppLayoutClass.tablet => const EdgeInsets.all(20),
      AppLayoutClass.mobile => const EdgeInsets.all(16),
    };
  }

  static double gap(AppLayoutClass layout) {
    return switch (layout) {
      AppLayoutClass.desktop => 24,
      AppLayoutClass.tablet => 20,
      AppLayoutClass.mobile => 16,
    };
  }

  static T value<T>(
    AppLayoutClass layout, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    return switch (layout) {
      AppLayoutClass.desktop => desktop,
      AppLayoutClass.tablet => tablet ?? desktop,
      AppLayoutClass.mobile => mobile,
    };
  }
}

class AppAdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? topBar;
  final Widget? drawer;
  final Widget? rail;
  final Widget? rightPanel;
  final Widget? footer;
  final Color? backgroundColor;
  final Decoration? decoration;
  final bool safeArea;
  final double railWidth;
  final double rightPanelWidth;
  final double gap;
  final EdgeInsetsGeometry bodyPadding;

  const AppAdaptiveScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.drawer,
    this.rail,
    this.rightPanel,
    this.footer,
    this.backgroundColor,
    this.decoration,
    this.safeArea = true,
    this.railWidth = 240,
    this.rightPanelWidth = 340,
    this.gap = 20,
    this.bodyPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.dashboardRail &&
            rail != null;
        final useRightPanel =
            constraints.maxWidth >= AppBreakpoints.dashboardRail &&
                rightPanel != null;

        Widget content = Column(
          children: [
            if (topBar != null) topBar!,
            Expanded(
              child: Padding(
                padding: bodyPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (useRail) ...[
                      SizedBox(width: railWidth, child: rail),
                      SizedBox(width: gap),
                    ],
                    Expanded(child: body),
                    if (useRightPanel) ...[
                      SizedBox(width: gap),
                      SizedBox(width: rightPanelWidth, child: rightPanel),
                    ],
                  ],
                ),
              ),
            ),
            if (footer != null) footer!,
          ],
        );

        if (decoration != null) {
          content = DecoratedBox(
            decoration: decoration!,
            child: content,
          );
        }

        if (safeArea) {
          content = SafeArea(child: content);
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          drawer: useRail ? null : drawer,
          body: content,
        );
      },
    );
  }
}

class AppResponsiveWidth extends StatelessWidget {
  final Widget child;
  final double tabletMaxWidth;
  final double desktopMaxWidth;
  final EdgeInsets? padding;

  const AppResponsiveWidth({
    super.key,
    required this.child,
    this.tabletMaxWidth = 840,
    this.desktopMaxWidth = 1180,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppBreakpoints.classify(constraints.maxWidth);
        final maxWidth = switch (layout) {
          AppLayoutClass.desktop => desktopMaxWidth,
          AppLayoutClass.tablet => tabletMaxWidth,
          AppLayoutClass.mobile => double.infinity,
        };

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ?? AppResponsive.pagePadding(layout),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout(
      {super.key,
      required this.mobile,
      required this.tablet,
      required this.desktop});

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppBreakpoints.mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final layout = AppBreakpoints.classify(constraints.maxWidth);
      if (layout.isDesktop) {
        return desktop;
      } else if (layout.isTablet) {
        return tablet;
      } else {
        return mobile;
      }
    });
  }
}
