import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/answered_question_record.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/providers/xp_provider.dart';
import '../../../game/providers/wallet_providers.dart'; // (added in Part B) incrementCoins/incrementGems
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_game_definition.dart';
import '../../domain/arcade_result.dart';
import '../../providers/arcade_providers.dart';
import 'arcade_results_modal.dart';
import 'quiz_review_screen.dart';

/// Public API exposed to Arcade games, so they can end a run cleanly.
class ArcadeRunApi {
  final ArcadeGameDefinition game;
  final ArcadeDifficulty difficulty;
  final Future<void> Function(ArcadeResult result) completeRun;

  const ArcadeRunApi({
    required this.game,
    required this.difficulty,
    required this.completeRun,
  });
}

class ArcadeGameShell extends ConsumerStatefulWidget {
  final ArcadeGameDefinition game;
  final ArcadeDifficulty difficulty;

  const ArcadeGameShell({
    super.key,
    required this.game,
    required this.difficulty,
  });

  static ArcadeRunApi of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ArcadeShellScope>();
    assert(scope != null,
        'ArcadeGameShell.of(context) called outside ArcadeGameShell');
    return scope!.api;
  }

  @override
  ConsumerState<ArcadeGameShell> createState() => _ArcadeGameShellState();
}

class _ArcadeGameShellState extends ConsumerState<ArcadeGameShell> {
  late final DateTime _startedAt;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startedAt = ref.read(arcadeSessionServiceProvider).startSession();
  }

  @override
  Widget build(BuildContext context) {
    final api = ArcadeRunApi(
      game: widget.game,
      difficulty: widget.difficulty,
      completeRun: completeRun,
    );

    return _ArcadeShellScope(
      api: api,
      // Build the game below the scope via a Builder so the context it receives
      // can resolve ArcadeGameShell.of(context); using this State's `context`
      // would look up from above the scope and find nothing.
      child: Builder(
        builder: (innerContext) =>
            widget.game.builder(innerContext, widget.difficulty),
      ),
    );
  }

  Future<void> completeRun(ArcadeResult rawResult) async {
    if (_completed) return;
    _completed = true;

    final session = ref.read(arcadeSessionServiceProvider);
    final duration = session.endSession(_startedAt);

    final result = ArcadeResult(
      gameId: rawResult.gameId,
      difficulty: rawResult.difficulty,
      score: rawResult.score,
      duration: duration, // shell is canonical for duration
      metadata: rawResult.metadata,
    );

    // Personal Best (PB) enrichment
    final pbService = ref.read(arcadePersonalBestServiceProvider);
    final previousBest = pbService.getBest(result.gameId, result.difficulty);
    final isNewPb = result.score > previousBest;
    if (isNewPb) {
      pbService.trySetBest(result);
    }

    final enrichedResult = ArcadeResult(
      gameId: result.gameId,
      difficulty: result.difficulty,
      score: result.score,
      duration: result.duration,
      metadata: {
        ...result.metadata,
        'isNewPb': isNewPb,
        'previousBest': previousBest,
      },
    );

    final rewardsService = ref.read(arcadeRewardsServiceProvider);
    final rewards = rewardsService.computeRewards(enrichedResult);
    // record run into local leaderboards
    ref.read(localArcadeLeaderboardServiceProvider).recordRun(enrichedResult);

    // submit score to backend (best-effort, non-blocking)
    unawaited(
      ref
          .read(arcadeLeaderboardApiServiceProvider)
          .submitScore(
            gameId: result.gameId.name,
            difficulty: result.difficulty.name,
            score: result.score,
            durationMs: result.duration.inMilliseconds,
          )
          .catchError((_) {}),
    );

    // XP (your canonical write path)
    incrementXP(ref, rewards.xp);

    // Coins + Gems (scaffolded in Part B)
    incrementCoins(ref, rewards.coins);
    incrementGems(ref, rewards.gems);

    // Analytics
    ref.read(arcadeAnalyticsServiceProvider).logGameCompleted(enrichedResult);
    ref.read(arcadeMissionServiceProvider).onArcadeRunCompleted(enrichedResult);

    if (!mounted) return;

    // Parse answered questions if available
    List<AnsweredQuestionRecord>? reviewRecords;
    final answeredQuestionsData = enrichedResult.metadata['answeredQuestions'];
    if (answeredQuestionsData is List) {
      reviewRecords = answeredQuestionsData
          .whereType<Map<String, dynamic>>()
          .map((json) => AnsweredQuestionRecord.fromJson(json))
          .toList();
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ArcadeResultsModal(
        result: enrichedResult,
        rewards: rewards,
        onPlayAgain: () {
          // for now, simplest: just pop back to hub and let user re-enter
          // (we can implement true replay-in-place after Step 8C)
        },
        onViewAllLocalScores: () {
          // navigate to Step 8C screen route
          // Example if you're using go_router:
          context.push('/arcade/local-scores');
        },
        onViewReview: reviewRecords != null && reviewRecords.isNotEmpty
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizReviewScreen(records: reviewRecords!),
                  ),
                );
              }
            : null,
      ),
    );

    if (!mounted) return;
    context.pop(); // back to hub
  }
}

class _ArcadeShellScope extends InheritedWidget {
  final ArcadeRunApi api;

  const _ArcadeShellScope({
    required this.api,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ArcadeShellScope oldWidget) {
    return oldWidget.api.game.id != api.game.id ||
        oldWidget.api.difficulty != api.difficulty;
  }
}
