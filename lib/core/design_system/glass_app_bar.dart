import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A high-intensity translucent header with dynamic glowing effects.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? color;
  final double blur;
  final double opacity;
  final double height;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.color,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.height = kToolbarHeight + 10,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = color ?? synaptix?.accentGlow ?? Colors.cyanAccent;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            border: Border(
              bottom: BorderSide(
                color: accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          child: NavigationToolbar(
            leading: leading,
            middle: DefaultTextStyle(
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: synaptix?.headlineFont,
                shadows: [
                  Shadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: title,
            ),
            trailing: actions != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
                : null,
            centerMiddle: true,
          ),
        ),
      ),
    );
  }
}
