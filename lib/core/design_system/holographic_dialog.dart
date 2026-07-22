import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';
import 'package:synaptix/ui_components/depth_card_3d/widgets/parallax_wrapper.dart';
import 'adaptive_glass_card.dart';

/// A 3D-interactive modal dialog with holographic depth.
///
/// Features a "Neural Snap" entrance animation and reacts to user touch/hover
/// using parallax tilt logic.
class HolographicDialog extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? glowColor;
  final bool showBlur;

  const HolographicDialog({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.glowColor,
    this.showBlur = true,
  });

  /// Static helper to show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    Color? glowColor,
    bool showBlur = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'HolographicDialog',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: HolographicDialog(
            width: width,
            height: height,
            glowColor: glowColor,
            showBlur: showBlur,
            child: child,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve =
            CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<HolographicDialog> createState() => _HolographicDialogState();
}

class _HolographicDialogState extends State<HolographicDialog> {
  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final useReducedMotion = synaptix?.useHighEnergyMotion == false;

    // Build the dialog content inside the parallax wrapper
    final dialogContent = AdaptiveGlassCard(
      glowColor: widget.glowColor,
      padding: EdgeInsets.zero, // Padding handled by child if needed
      showBlur: widget.showBlur,
      child: SizedBox(
        width: widget.width ?? 320,
        height: widget.height,
        child: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ),
    );

    if (useReducedMotion) {
      return dialogContent;
    }

    return ParallaxWrapper(
      depth: 0.05, // Subtle tilt for modals
      builder: (context, tilt) {
        return dialogContent;
      },
    );
  }
}
