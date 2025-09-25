// core/depth_card_3d.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import 'depth_card_config.dart';
import '../widgets/interactive_overlay.dart';
import '../widgets/parallax_wrapper.dart';
import '../widgets/shadow_layer.dart';
import '../widgets/background_layer.dart';
import '../widgets/extruded_text.dart';

class DepthCard3D extends StatefulWidget {
  final DepthCardConfig config;

  const DepthCard3D({super.key, required this.config});

  @override
  State<DepthCard3D> createState() => _DepthCard3DState();
}

class _DepthCard3DState extends State<DepthCard3D> {
  late Flutter3DController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
    // Optional: _controller?.setupScene(widget.config.lightingOptions);
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ParallaxWrapperBuilder(
      depth: widget.config.parallaxDepth,
      builder: (context, tilt) {
        return ShadowLayer(
          theme: widget.config.theme,
          child: SizedBox(
            width: widget.config.width,
            height: widget.config.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.config.borderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background (slow parallax)
                  Transform.translate(
                    offset: Offset(tilt.dx * 6 * 0.35, tilt.dy * 6 * 0.35),
                    child: RepaintBoundary(
                      child: widget.config.backgroundImage != null
                          ? ColorFiltered(
                        colorFilter: widget.config.backgroundBlendMode != null
                            ? ColorFilter.mode(
                          Colors.black.withOpacity(0.0),
                          widget.config.backgroundBlendMode!,
                        )
                            : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.srcOver,
                        ),
                        child: BackgroundLayer(
                          image: widget.config.backgroundImage!,
                          fit: widget.config.backgroundFit,
                          alignment: widget.config.backgroundAlignment,
                          opacity: widget.config.backgroundOpacity,
                          blur: widget.config.backgroundBlur,
                          kenBurns: widget.config.backgroundKenBurns,
                          filterQuality: widget.config.backgroundFilterQuality, // 👈 safe sampling
                          isAntiAlias: false,
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // 3D model (medium parallax)
                  Transform.translate(
                    offset: Offset(tilt.dx * 6 * 0.65, tilt.dy * 6 * 0.65),
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        ignoring: true,
                        child: Flutter3DViewer(
                          controller: _controller,
                          src: widget.config.modelAssetPath,
                        ),
                      ),
                    ),
                  ),

                  // Optional vignette to unify brand color
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.config.theme.overlayColor.withOpacity(0.30),
                          Colors.transparent,
                          widget.config.theme.overlayColor.withOpacity(0.20),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Foreground/UI (fast parallax)
                  Transform.translate(
                    offset: Offset(tilt.dx * 6 * 1.0, tilt.dy * 6 * 1.0),
                    child: Stack(
                      children: [
                        if (widget.config.slots.topLeft != null)
                          Positioned(top: 10, left: 10, child: widget.config.slots.topLeft!),
                        if (widget.config.slots.topRight != null)
                          Positioned(top: 10, right: 10, child: widget.config.slots.topRight!),
                        if (widget.config.slots.bottomLeft != null)
                          Positioned(bottom: 10, left: 10, child: widget.config.slots.bottomLeft!),
                        if (widget.config.slots.bottomRight != null)
                          Positioned(bottom: 10, right: 10, child: widget.config.slots.bottomRight!),
                        if (widget.config.slots.center != null)
                          Align(alignment: Alignment.center, child: widget.config.slots.center!),

                        // Faux-3D title with glass band for legibility
                        if (widget.config.show3DText)
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    color: Colors.black.withOpacity(0.25),
                                    child: ExtrudedText(
                                      text: widget.config.text,
                                      style: widget.config.textStyle.copyWith(
                                        color: widget.config.theme.textColor,
                                      ),
                                      depth: widget.config.textDepth,
                                      elevation: widget.config.textElevation,
                                      shine: widget.config.textShine,
                                      tilt: tilt,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Interactive overlay (tap/actions)
                        InteractiveOverlay(
                          text: widget.config.text,
                          onTap: widget.config.onTap,
                          actions: widget.config.overlayActions,
                          height: widget.config.height,
                          width: widget.config.width,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

