import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mode/synaptix_mode.dart';
import '../mode/synaptix_mode_provider.dart';

/// Horizontal auto-scrolling ticker showing live player events.
///
/// Follows the [TickerTapeWidget] pattern using flutter_animate's
/// `.slideX()` with `controller.repeat()` for continuous scrolling.
class HubLiveTicker extends ConsumerWidget {
  const HubLiveTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(synaptixModeProvider);
    final items = _tickerItems(mode);
    final text = items.join('   •   ');

    return Container(
      height: 28,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
          bottom: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
        ),
      ),
      child: ClipRect(
        child: SizedBox(
          height: 28,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 100,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    color: Color(0xFF50C878),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).slideX(
                begin: -1,
                end: 0,
                duration: 8.seconds,
                curve: Curves.linear,
              ),
        ),
      ),
    );
  }

  // TODO: Replace with live data from a provider/stream
  List<String> _tickerItems(SynaptixMode mode) {
    final prefix = mode == SynaptixMode.kids;
    return [
      '${prefix ? '🏆 ' : ''}User_882 won 500 Coins in Science',
      '${prefix ? '🔥 ' : ''}PlayerX secured a 10-streak in Tech',
      '${prefix ? '⭐ ' : ''}LizK reached Arena Rank 5',
      '${prefix ? '🎯 ' : ''}NovaMind completed Daily Signal',
      '${prefix ? '💎 ' : ''}QuizPro unlocked Diamond tier',
    ];
  }
}
