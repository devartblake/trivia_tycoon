import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../extensions/flutter_3d_controller_dispose_extension.dart';
import '../models/depth_card_config.dart';
import '../utils/performance_utils.dart';
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
  final Flutter3DController _controller = Flutter3DController();

  @override
  void initState() {
    super.initState();
    // Optional: _controller?.setupScene(widget.config.lightingOptions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return PerformanceUtils.rebuildBoundary(
      child: GestureDetector(
        onTap: config.onTap,
        child: ParallaxWrapper(
          depth: config.parallaxDepth,
          builder: (context, tilt) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(config.borderRadius),
              child: SizedBox(
                width: config.width,
                height: config.height,
                child: Stack(
                  children: [
                    // Background layer
                    BackgroundLayer(
                      theme: config.theme,
                      image: widget.config.backgroundImage!,
                      tilt: tilt,
                    ),

                    // Shadow layer (subtle depth)
                    ShadowLayer(
                      theme: config.theme,
                      tilt: tilt,
                    ),

                    // Main visual layer (3D model OR flat image OR none)
                    Transform.translate(
                      offset: Offset(tilt.dx * 6 * 0.65, tilt.dy * 6 * 0.65),
                      child: RepaintBoundary(
                        child: IgnorePointer(
                          // If you want the embedded 3D model to be interactive,
                          // set this to false and make sure gesture priorities are handled.
                          ignoring: true,
                          child: _buildMainVisual(),
                        ),
                      ),
                    ),

                    // Slots (badges, chips, etc.)
                    if (widget.config.slots.topLeft != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: widget.config.slots.topLeft!,
                      ),
                    if (widget.config.slots.topRight != null)
                      Align(
                        alignment: Alignment.topRight,
                        child: widget.config.slots.topRight!,
                      ),
                    if (widget.config.slots.bottomLeft != null)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: widget.config.slots.bottomLeft!,
                      ),
                    if (widget.config.slots.bottomRight != null)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: widget.config.slots.bottomRight!,
                      ),
                    if (widget.config.slots.center != null)
                      Align(
                        alignment: Alignment.center,
                        child: widget.config.slots.center!,
                      ),

                    // Optional additional overlays (UI-only).
                    if (widget.config.overlayWidgets.isNotEmpty)
                      Positioned.fill(
                        child: Stack(children: widget.config.overlayWidgets),
                      ),

                    // Extruded text (top)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: ExtrudedText(
                          text: config.text,
                          style: TextStyle(
                            fontSize: config.theme.titleFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: config.theme.titleColor,
                          ),
                          tilt: tilt,
                        ),
                      ),
                    ),

                    // Interactive overlay (glass + highlight)
                    InteractiveOverlay(
                      theme: config.theme,
                      tilt: tilt,
                      text: '',
                      width: 120,
                      height: 120,
                    ),

                    // Action buttons (bottom-right)
                    if (config.overlayActions != null &&
                        config.overlayActions!.isNotEmpty)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: config.overlayActions!
                              .map((a) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: a.build(context),
                              )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main visual selection (3D vs image vs none)
  // ---------------------------------------------------------------------------

  Widget _buildMainVisual() {
    final path = widget.config.modelAssetPath.trim();
    if (path.isEmpty) return const SizedBox.shrink();

    if (_is3d(path)) {
      return Flutter3DViewer(
        controller: _controller,
        src: path,
        progressBarColor: Colors.white,
        onProgress: (progressValue) {},
        onLoad: (modelAddress) {},
      );
    }

    if (_isImage(path)) {
      return _imageFromPath(path);
    }

    // Unknown content type. Do not crash; just render nothing.
    return const SizedBox.shrink();
  }

  bool _is3d(String p) {
    final l = p.toLowerCase();
    return l.endsWith('.glb') || l.endsWith('.gltf');
  }

  bool _isImage(String p) {
    final l = p.toLowerCase();
    return l.endsWith('.png') ||
        l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.webp');
  }

  Widget _imageFromPath(String path) {
    // Heuristic: treat assets/ as bundled assets; everything else as file path.
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
