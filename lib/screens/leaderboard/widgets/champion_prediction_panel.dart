import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/models/champion_prediction.dart';
import '../../../game/providers/arcade_providers.dart';
import '../../../game/providers/core_providers.dart' show apiServiceProvider;

/// No-loss prediction panel for a Champion vs Tier event: "Will the champion
/// defend the crown?" Everyone can pick while the event is open; correct
/// predictors share a coin pool at close. Hides itself when there's nothing
/// to show.
class ChampionPredictionPanel extends ConsumerStatefulWidget {
  final String gameEventId;
  const ChampionPredictionPanel({super.key, required this.gameEventId});

  @override
  ConsumerState<ChampionPredictionPanel> createState() =>
      _ChampionPredictionPanelState();
}

class _ChampionPredictionPanelState
    extends ConsumerState<ChampionPredictionPanel> {
  bool _submitting = false;

  Future<void> _pick(bool championDefends) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiServiceProvider).submitPrediction(
            gameEventId: widget.gameEventId,
            championDefends: championDefends,
          );
      ref.invalidate(championPredictionProvider(widget.gameEventId));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p =
        ref.watch(championPredictionProvider(widget.gameEventId)).valueOrNull;
    // Only meaningful while open or once the caller has a result.
    if (p == null || (!p.open && !p.resolved && !p.hasPicked)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.online_prediction_rounded,
                  color: Color(0xFF60A5FA), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Will the Champion defend the crown?',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              if (p.rewardCoinPool > 0 && !p.resolved)
                Text('🏆 ${p.rewardCoinPool} pool',
                    style: const TextStyle(
                        color: Color(0xFFFCD34D), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              'Free to predict — win a share of the pool if you call it.',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 12),
          if (p.resolved)
            _result(p)
          else if (p.open)
            _picker(p)
          else
            _locked(p),
          if (p.totalPredictions > 0) ...[
            const SizedBox(height: 12),
            _tallyBar(p),
          ],
        ],
      ),
    );
  }

  Widget _picker(ChampionPrediction p) {
    return Row(
      children: [
        Expanded(
          child: _choiceButton(
            label: 'Defends 🛡️',
            selected: p.myPrediction == true,
            color: const Color(0xFF10B981),
            onTap: _submitting ? null : () => _pick(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _choiceButton(
            label: 'Dethroned ⚔️',
            selected: p.myPrediction == false,
            color: const Color(0xFFEF4444),
            onTap: _submitting ? null : () => _pick(false),
          ),
        ),
      ],
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: selected ? color.withValues(alpha: 0.28) : Colors.white10,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : Colors.white24,
                width: selected ? 1.6 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? color : Colors.white,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _locked(ChampionPrediction p) {
    final pick = p.myPrediction;
    return Text(
      pick == null
          ? 'Predictions are locked — the match has begun.'
          : 'Locked in: you predicted the champion '
              '${pick ? 'defends 🛡️' : 'is dethroned ⚔️'}.',
      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
    );
  }

  Widget _result(ChampionPrediction p) {
    final correct = p.wasCorrect == true;
    if (p.myPrediction == null) {
      return const Text('This match has ended.',
          style: TextStyle(color: Colors.white70, fontSize: 12.5));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (correct ? const Color(0xFF10B981) : const Color(0xFFEF4444))
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: correct ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
      ),
      child: Text(
        correct
            ? 'You called it! +${p.rewardCoins} coins'
                '${p.rewardXp > 0 ? ' · +${p.rewardXp} XP' : ''}'
            : 'Not this time — better luck next event.',
        style: TextStyle(
            color: correct ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _tallyBar(ChampionPrediction p) {
    final total = p.totalPredictions;
    final defendFrac = total == 0 ? 0.5 : p.defendCount / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: (defendFrac * 1000).round().clamp(1, 1000),
                child: Container(height: 8, color: const Color(0xFF10B981)),
              ),
              Expanded(
                flex: ((1 - defendFrac) * 1000).round().clamp(1, 1000),
                child: Container(height: 8, color: const Color(0xFFEF4444)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${p.defendCount} say defends · ${p.dethroneCount} say dethroned',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
