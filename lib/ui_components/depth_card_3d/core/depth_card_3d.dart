import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'depth_card_config.dart';
import '../widgets/interactive_overlay.dart';
import '../widgets/parallax_wrapper.dart';
import '../widgets/shadow_layer.dart';

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

    // Optional: load 3D model or apply real-time lighting settings
    //_controller?.setupScene(widget.config.lightingOptions);
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ParallaxWrapper(
      depth: widget.config.parallaxDepth,
      child: Stack(
        children: [
          // 3D Background & Shadow Layer
          ShadowLayer(
            theme: widget.config.theme,
            child: Container(
              width: widget.config.width,
              height: widget.config.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: widget.config.backgroundImage,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(widget.config.borderRadius),
              ),
              child: Flutter3DViewer(
                controller: _controller,
                src: widget.config.modelAssetPath,

              ),
            ),
          ),

          // Overlay with bottom text & interactive elements
          InteractiveOverlay(
            text: widget.config.text,
            onTap: widget.config.onTap,
            actions: widget.config.overlayActions,
            height: widget.config.height,
            width: widget.config.width,
          ),
        ],
      ),
    );
  }
}
