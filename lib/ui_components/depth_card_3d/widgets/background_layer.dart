import 'dart:ui';
import 'package:flutter/material.dart';

/// Animated background image with optional blur + Ken Burns pan/zoom.
/// Uses FilterQuality.low by default to avoid Impeller mipmap sampling crashes
/// when textures don't have generated mip levels.
class BackgroundLayer extends StatefulWidget {
  final ImageProvider image;
  final BoxFit fit;
  final Alignment alignment;
  final double opacity;
  final double blur; // sigma
  final bool kenBurns;
  final Duration kenBurnsDuration;

  /// Important: keep LOW unless you know your textures have mipmaps.
  final FilterQuality filterQuality;
  final bool isAntiAlias;

  const BackgroundLayer({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.opacity = 1.0,
    this.blur = 0.0,
    this.kenBurns = true,
    this.kenBurnsDuration = const Duration(seconds: 14),
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
  });

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: widget.kenBurnsDuration,
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween(begin: 1.02, end: 1.08).animate(
    CurvedAnimation(parent: _ac, curve: Curves.easeInOut),
  );

  late final Animation<Alignment> _align =
  AlignmentTween(begin: const Alignment(-0.08, -0.06), end: const Alignment(0.08, 0.06))
      .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ac.dispose();
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
      filterQuality: widget.filterQuality, // 👈 keep low unless you have mipmaps
      isAntiAlias: widget.isAntiAlias,     // 👈 false helps avoid higher-quality sampling
    );

    if (widget.blur > 0) {
      img = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: img,
      );
    }

    return Opacity(
      opacity: widget.opacity,
      child: Transform.scale(
        scale: widget.kenBurns ? _scale.value : 1.0,
        child: img,
      ),
    );
  }
}
