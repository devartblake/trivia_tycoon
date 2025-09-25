import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/screens/question/score_summary_screen.dart';
import 'package:trivia_tycoon/screens/question/widgets/score_summary/tier_progression_dialog.dart';
import '../../game/logic/quiz_completion_handler.dart';
import '../../game/providers/quiz_results_provider.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../game/state/tier_update_result.dart';

class ScoreSummaryScreenWrapper extends ConsumerStatefulWidget {
  const ScoreSummaryScreenWrapper({super.key});

  @override
  ConsumerState<ScoreSummaryScreenWrapper> createState() => _ScoreSummaryScreenWrapperState();
}

class _ScoreSummaryScreenWrapperState extends ConsumerState<ScoreSummaryScreenWrapper> {
  bool _hasProcessedResults = false;
  TierUpdateResult? _tierResult;

  @override
  void initState() {
    super.initState();
    // Process quiz results when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processQuizCompletion();
    });
  }

  Future<void> _processQuizCompletion() async {
    if (_hasProcessedResults) return;

    final results = ref.read(quizResultsProvider);
    if (results != null) {
      try {
        // Process quiz completion and get tier result
        await ProfileDataUpdater.updateAfterQuiz(ref, results);

        // Get tier progression result for display
        final tierManager = ref.read(tierManagerProvider);
        _tierResult = await tierManager.updateTierProgress();

        _hasProcessedResults = true;

        // Show tier progression dialog if tier changed
        if (_tierResult?.tierChanged == true) {
          _showTierProgressionDialog();
        }

        debugPrint('Educational data updated successfully for quiz completion');
      } catch (e) {
        debugPrint('Error updating educational data: $e');
      }
    }
  }

  void _showTierProgressionDialog() {
    if (_tierResult == null || !_tierResult!.tierChanged) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TierProgressionDialog(
        tierResult: _tierResult!,
        onDismissed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(quizResultsProvider);

    if (results == null) {
      // Handle case where no results are available
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No quiz results available'),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    // Debug print for duration tracking
    debugPrint('Quiz Duration: ${results.quizDuration.inMinutes}m ${results.quizDuration.inSeconds % 60}s');

    return EnhancedScoreSummaryScreen(
      score: results.score,
      totalQuestions: results.totalQuestions,
      totalXP: results.totalXP,
      coins: results.coins,
      diamonds: results.diamonds,
      stars: results.stars,
      classLevel: results.classLevel,
      category: results.category,
      categoryScores: results.categoryScores,
      achievements: results.achievements,
      quizDuration: results.quizDuration,
      tierResult: _tierResult,
    );
  }
}
