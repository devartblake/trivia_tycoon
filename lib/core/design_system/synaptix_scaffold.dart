import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';
import 'interactive_glow_surface.dart';

/// The foundation scaffold for the Synaptix "Neon Glass" design system.
class SynaptixScaffold extends ConsumerWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool showParticles;

  const SynaptixScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
    this.showParticles = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: synaptix?.primarySurface ?? const Color(0xFF0F0F23),
      body: InteractiveGlowSurface(
        child: Stack(
          children: [
            // 1. Dynamic Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: synaptix?.mainBackgroundGradient ??
                      const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF0F0F23)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                ),
              ),
            ),

            // 2. Base Body
            body,
          ],
        ),
      ),
    );
  }
}
