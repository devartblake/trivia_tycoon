import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';

import '../../../game/providers/riverpod_providers.dart';
import '../../domain/arcade_game_id.dart';
import '../../domain/arcade_result.dart';

class ArcadeResultsModal extends StatelessWidget {
  final ArcadeResult result;
  final ArcadeRewards rewards;

  // Optional actions
  final VoidCallback? onPlayAgain;
  final VoidCallback? onViewAllLocalScores;

  const ArcadeResultsModal({
    super.key,
    required this.result,
    required this.rewards,
    this.onPlayAgain,
    this.onViewAllLocalScores,
  });

  @override
  Widget build(BuildContext context) {
    final meta = result.metadata;
    final bool isNewPb = meta['isNewPb'] == true;
    final int previousBest = (meta['previousBest'] as int?) ?? 0;

    // Bottom sheets can be height constrained. We harden the layout by:
    // - bounding height
    // - making the body scrollable
    // - pinning the CTA at the bottom
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Give the sheet a sensible cap so it doesn’t feel full-screen,
          // while still allowing scroll if content grows.
          final maxSheetHeight = constraints.maxHeight * 0.92;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxSheetHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Grabber
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Scrollable body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Run Complete',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

                          // Score
                          Text(
                            '${result.score}',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),

                          const SizedBox(height: 8),

                          // PB badge
                          if (isNewPb) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'NEW PERSONAL BEST',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],

                          // Previous best text
                          if (previousBest > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              isNewPb
                                  ? 'Previous best: $previousBest'
                                  : 'Personal best: $previousBest',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Local leaderboard preview
                          LocalLeaderboardPreview(
                            gameId: result.gameId,
                            difficulty: result.difficulty,
                          ),

                          const SizedBox(height: 14),
                          const Divider(color: Colors.white12),

                          _statRow(
                              context, 'Difficulty', result.difficulty.label),
                          _statRow(context, 'Duration',
                              _formatDuration(result.duration)),

                          const SizedBox(height: 14),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 10),

                          _statRow(context, 'XP', '+${rewards.xp}'),
                          _statRow(context, 'Coins', '+${rewards.coins}'),
                          _statRow(context, 'Gems', '+${rewards.gems}'),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // Pinned CTA
                  const SizedBox(height: 10),
                  _buildBottomActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final hasPlayAgain = onPlayAgain != null;
    final hasViewScores = onViewAllLocalScores != null;

    // Original behavior: only Continue if no optional actions are provided
    if (!hasPlayAgain && !hasViewScores) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      );
    }

    // Otherwise: show optional actions + Continue
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPlayAgain)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onPlayAgain?.call();
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (hasPlayAgain) const SizedBox(height: 10),
        if (hasViewScores)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onViewAllLocalScores?.call();
              },
              icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
              label: const Text(
                'View All Local Scores',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (hasViewScores) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
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

class LocalLeaderboardPreview extends ConsumerWidget {
  final ArcadeGameId gameId;
  final ArcadeDifficulty difficulty;

  const LocalLeaderboardPreview({
    super.key,
    required this.gameId,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(localArcadeLeaderboardProvider);
    final entries = service.top(gameId, difficulty, limit: 5);

    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        );

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          'Local Leaderboard\nNo local scores yet.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Local Leaderboard', style: titleStyle),
          const SizedBox(height: 10),

          // Important: keep this NON-scrollable since parent is already scrollable.
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final entry = entries[index];

              return Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.score} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.durationMs} ms',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
