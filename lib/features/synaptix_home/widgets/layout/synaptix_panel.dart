import 'package:flutter/material.dart';

import '../../theme/synaptix_home_theme.dart';

class SynaptixPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? minHeight;
  final VoidCallback? onTap;

  const SynaptixPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.height,
    this.minHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      height: height,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panel.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: SynaptixHomeTheme.stroke.withValues(alpha: 0.90)),
        boxShadow: [
          BoxShadow(
            color: SynaptixHomeTheme.purple.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: panel,
      ),
    );
  }
}
