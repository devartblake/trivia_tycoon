import 'package:flutter/material.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import '../../domain/arcade_result.dart';

class ArcadeResultsModal extends StatelessWidget {
  final ArcadeResult result;
  final ArcadeRewards rewards;

  const ArcadeResultsModal({
    super.key,
    required this.result,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Run Complete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          _statRow('Score', '${result.score}'),
          _statRow('Difficulty', result.difficulty.label),
          _statRow('Duration', _formatDuration(result.duration)),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),
          _statRow('XP', '+${rewards.xp}'),
          _statRow('Coins', '+${rewards.coins}'),
          _statRow('Gems', '+${rewards.gems}'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.70)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m <= 0) return '${s}s';
    return '${m}m ${s}s';
  }
}
