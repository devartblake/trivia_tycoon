import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../game/services/question_loader_service.dart';
import '../../../../game/models/question_model.dart';

// Provider for featured challenge data
final featuredChallengeProvider = FutureProvider<FeaturedChallenge>((ref) async {
  final loader = AdaptedQuestionLoaderService();

  try {
    // Get featured challenge questions - using science as an example with bonus questions
    final questions = await loader.getMixedQuiz(
      questionCount: 10,
      categories: ['science', 'technology'], // Featured categories
      difficulties: ['hard'], // Featured challenges are hard
      datasets: ['Science & Technology', 'Bonus Questions'], // Use bonus dataset if available
    );

    return FeaturedChallenge(
      title: 'Science Masters Quiz',
      description: 'Test your advanced knowledge in science and technology',
      questions: questions,
      totalQuestions: questions.length,
      difficulty: 'Expert',
      xpMultiplier: 2, // 2x XP bonus
      bonusReward: 'Exclusive Science Badge',
      timeLimit: 600, // 10 minutes
      isUnlocked: true, // TODO: Check user level/achievements
      participantCount: 1247, // TODO: Get from backend
      completionRate: 0.23, // 23% completion rate
    );
  } catch (e) {
    debugPrint('Error loading featured challenge: $e');
    rethrow;
  }
});

class FeaturedChallengeWidget extends ConsumerWidget {
  const FeaturedChallengeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(featuredChallengeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: challengeAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(context, ref),
        data: (challenge) => _buildDataState(context, challenge),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Featured Challenge",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Loading...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Featured Challenge",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Error loading challenge",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(featuredChallengeProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.white,
            size: 35,
          ),
        ),
      ],
    );
  }

  Widget _buildDataState(BuildContext context, FeaturedChallenge challenge) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      "Featured Challenge",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                challenge.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${challenge.xpMultiplier}x XP Bonus",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: challenge.isUnlocked
                    ? () => _handleChallengeTap(context, challenge)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: challenge.isUnlocked ? Colors.white : Colors.white54,
                  foregroundColor: Colors.indigo.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  challenge.isUnlocked ? "Accept Challenge" : "Locked",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 35,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.indigo.shade600,
                  size: 14,
                ),
              ),
            ),
            if (challenge.participantCount > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatParticipantCount(challenge.participantCount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _handleChallengeTap(BuildContext context, FeaturedChallenge challenge) {
    // Navigate to featured challenge screen
    context.push('/featured-challenge');
  }

  String _formatParticipantCount(int count) {
    if (count < 1000) {
      return '$count';
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}

// Data model for featured challenge
class FeaturedChallenge {
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final int totalQuestions;
  final String difficulty;
  final int xpMultiplier;
  final String bonusReward;
  final int timeLimit; // in seconds
  final bool isUnlocked;
  final int participantCount;
  final double completionRate;

  const FeaturedChallenge({
    required this.title,
    required this.description,
    required this.questions,
    required this.totalQuestions,
    required this.difficulty,
    required this.xpMultiplier,
    required this.bonusReward,
    required this.timeLimit,
    required this.isUnlocked,
    required this.participantCount,
    required this.completionRate,
  });
}
