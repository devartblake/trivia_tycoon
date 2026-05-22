import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reward_reactor_providers.dart';
import 'reactor_action_controls.dart';
import 'reactor_particle_layer.dart';
import 'reactor_reel_column.dart';
import 'reactor_reward_banner.dart';

class ArcadeRewardMachineWidget extends ConsumerWidget {
  const ArcadeRewardMachineWidget({super.key});

  static const int _reelCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reactorProvider);
    final isSpinning = state.phase == ReactorPhase.spinning;
    final showBanner = state.phase == ReactorPhase.pendingClaim ||
        state.phase == ReactorPhase.applied ||
        state.phase == ReactorPhase.claiming;

    final animation = state.pendingReward?.animation;
    final symbols = animation?.symbols ?? const ['coin', 'gem', 'star'];
    final winningIndexes = animation?.winningSymbolIndexes ?? const [0, 0, 0];
    final perReelSymbols = _splitSymbols(symbols, _reelCount);

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildReels(perReelSymbols, winningIndexes, isSpinning),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: showBanner && state.pendingReward != null
                  ? ReactorRewardBanner(
                      key: ValueKey(state.pendingReward!.spinId),
                      preview: state.pendingReward!.rewardPreview,
                    )
                  : const SizedBox(height: 80),
            ),
            const ReactorActionControls(),
          ],
        ),
        ReactorParticleLayer(active: state.phase == ReactorPhase.applied),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          '⚡ REWARD REACTOR',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Daily Login Reward',
          style: TextStyle(color: Color(0xFF9D8EC0), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildReels(
    List<List<String>> perReelSymbols,
    List<int> winningIndexes,
    bool isSpinning,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0924),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D2E7C), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_reelCount, (i) {
          final reelSymbols = i < perReelSymbols.length
              ? perReelSymbols[i]
              : const ['coin', 'gem', 'star'];
          final winIdx = i < winningIndexes.length ? winningIndexes[i] : 0;
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: ReactorReelColumn(
              symbols: reelSymbols,
              winningSymbolIndex: winIdx,
              isSpinning: isSpinning,
              stopDelay: Duration(milliseconds: i * 200),
            ),
          );
        }),
      ),
    );
  }

  static List<List<String>> _splitSymbols(List<String> symbols, int reels) {
    if (symbols.isEmpty) {
      return List.generate(reels, (_) => ['coin', 'gem', 'star']);
    }
    final perReel = (symbols.length / reels).ceil();
    return List.generate(reels, (i) {
      final start = i * perReel;
      if (start >= symbols.length) return symbols;
      return symbols.sublist(start, (start + perReel).clamp(0, symbols.length));
    });
  }
}
