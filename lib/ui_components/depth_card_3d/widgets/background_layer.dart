import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/depth_card_theme.dart';

/// Animated background image with optional blur + Ken Burns pan/zoom.
/// Uses FilterQuality.low by default to avoid Impeller mipmap sampling crashes
/// when textures don't have generated mip levels.
class BackgroundLayer extends StatefulWidget {
  final ImageProvider image;

  /// Optional theme (used by DepthCard3D). If not provided, this widget
  /// behaves exactly as before.
  final DepthCardTheme? theme;

  /// Optional parallax tilt (used by DepthCard3D).
  final Offset tilt;

  final BoxFit fit;
  final double opacity;
  final double blur;
  final double blurSigma;
  final bool kenBurns;
  final Alignment alignment;
  final Duration kenBurnsDuration;

  /// Important: keep LOW unless you know your textures have mipmaps.
  final FilterQuality filterQuality;
  final bool isAntiAlias;

  const BackgroundLayer({
    super.key,
    required this.image,
    this.theme,
    this.tilt = Offset.zero,
    this.fit = BoxFit.cover,
    this.opacity = 1.0,
    this.blur = 0.0,
    this.blurSigma = 0.1,
    this.kenBurns = true,
    this.alignment = Alignment.center,
    this.kenBurnsDuration = const Duration(seconds: 14),
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
  });

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller =
      AnimationController(vsync: this, duration: widget.kenBurnsDuration)
        ..repeat(reverse: true);
  late Animation<double> _scale = Tween(begin: 1.02, end: 1.08)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  late final Animation<Alignment> _align = AlignmentTween(
          begin: const Alignment(-0.08, -0.06),
          end: const Alignment(0.08, 0.06))
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.kenBurns) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kenBurns != widget.kenBurns) {
      if (widget.kenBurns) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget img = Image(
      image: widget.image,
      fit: widget.fit,
      alignment: widget.kenBurns ? _align.value : widget.alignment,
      width: double.infinity,
      height: double.infinity,
      filterQuality:
          widget.filterQuality, // 👈 keep low unless you have mipmaps
      isAntiAlias:
          widget.isAntiAlias, // 👈 false helps avoid higher-quality sampling
    );

    if (widget.blur > 0) {
      img = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: img,
      );
    }

    // Subtle translation based on tilt for a low-cost parallax effect.
    // Keep the multipliers small to avoid visible edge gaps.
    final parallaxOffset = Offset(widget.tilt.dx * 8.0, widget.tilt.dy * 8.0);

    return Opacity(
      opacity: widget.opacity,
      child: Transform.translate(
        offset: parallaxOffset,
        child: Transform.scale(
          scale: widget.kenBurns ? _scale.value : 1.0,
          child: img,
        ),
      ),
    );
  }
}
