import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// High-emphasis text with multi-layered neon drop shadows.
class GlowText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool isHeadline;
  final bool pulse;

  const GlowText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.isHeadline = true,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = style?.color ?? synaptix?.accentGlow ?? Colors.cyanAccent;

    final defaultStyle = TextStyle(
      fontFamily: isHeadline ? synaptix?.headlineFont : synaptix?.bodyFont,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: accent.withValues(alpha: 0.8),
          blurRadius: 8,
        ),
        Shadow(
          color: accent.withValues(alpha: 0.4),
          blurRadius: 16,
        ),
      ],
    );

    return Text(
      data,
      textAlign: textAlign,
      style: defaultStyle.merge(style),
    );
  }
}
