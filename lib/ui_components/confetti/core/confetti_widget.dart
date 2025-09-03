import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../core/confetti_theme.dart';
import '../core/confetti_controller.dart';
import '../core/confetti_painter.dart';

class ConfettiWidget extends ConsumerWidget {
  const ConfettiWidget({
    super.key,
    required ConfettiController controller,
    required ConfettiTheme theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confettiController = ref.watch(confettiControllerProvider);
    final currentTheme = confettiController.currentTheme;

    return CustomPaint(
      painter: ConfettiPainter(currentTheme),
      child: const SizedBox.expand(),
    );
  }
}
