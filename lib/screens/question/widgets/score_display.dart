import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnhancedScoreDisplay extends ConsumerStatefulWidget {
  final int score;
  final int totalQuestions;
  final int totalXP;
  final String classLevel;
  final Map<String, int> categoryScores;
  final Duration? powerUpTimeRemaining;

  const EnhancedScoreDisplay({
    super.key,
    required this.score,
    required this.totalQuestions,
    this.totalXP = 0,
    this.classLevel = '1',
    this.categoryScores = const {},
    this.powerUpTimeRemaining,
  });

  @override
  ConsumerState<EnhancedScoreDisplay> createState() => _EnhancedScoreDisplayState();
}

class _EnhancedScoreDisplayState extends ConsumerState<EnhancedScoreDisplay>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late AnimationController _xpAnimationController;
  late Animation<int> _scoreAnimation;
  late Animation<int> _xpAnimation;

  @override
  void initState() {
    super.initState();

    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scoreAnimation = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _scoreAnimationController, curve: Curves.easeOut),
    );

    _xpAnimation = IntTween(begin: 0, end: widget.totalXP).animate(
      CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeOut),
    );

    // Start animations
    _scoreAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _xpAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _xpAnimationController.dispose();
    super.dispose();
  }

  Color _getClassColor() {
    switch (widget.classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return Colors.pink;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  String _getPerformanceMessage() {
    final percentage = (widget.score / widget.totalQuestions) * 100;

    if (percentage >= 90) return "Outstanding work!";
    if (percentage >= 80) return "Great job!";
    if (percentage >= 70) return "Good effort!";
    if (percentage >= 60) return "Keep trying!";
    return "Practice makes perfect!";
  }

  IconData _getPerformanceIcon() {
    final percentage = (widget.score / widget.totalQuestions) * 100;

    if (percentage >= 90) return Icons.star;
    if (percentage >= 80) return Icons.thumb_up;
    if (percentage >= 70) return Icons.sentiment_satisfied;
    if (percentage >= 60) return Icons.sentiment_neutral;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor();
    final percentage = (widget.score / widget.totalQuestions) * 100;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            classColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: classColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Class Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: classColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 16, color: classColor),
                    const SizedBox(width: 6),
                    Text(
                      'Class ${widget.classLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: classColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _getPerformanceIcon(),
                color: classColor,
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Score Display
          Column(
            children: [
              Text(
                "Your Score",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 8),

              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _scoreAnimation.value.toString(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: classColor,
                        ),
                      ),
                      Text(
                        " / ${widget.totalQuestions}",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // Percentage and Performance Message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: classColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "${percentage.round()}%",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: classColor,
                      ),
                    ),
                    Text(
                      _getPerformanceMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: classColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // XP Display (if applicable)
          if (widget.totalXP > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Experience Points",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _xpAnimation,
                          builder: (context, child) {
                            return Text(
                              "${_xpAnimation.value} XP",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Category Breakdown (if available)
          if (widget.categoryScores.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCategoryBreakdown(),
          ],

          // Power-Up Status (if active)
          if (widget.powerUpTimeRemaining != null) ...[
            const SizedBox(height: 16),
            _buildPowerUpStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                "Subject Performance",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...widget.categoryScores.entries.map((entry) {
            final categoryColor = _getCategoryColor(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.toLowerCase().replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${entry.value}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPowerUpStatus() {
    final remainingSeconds = widget.powerUpTimeRemaining!.inSeconds;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flash_on,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Power-Up Active",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          Text(
            "${remainingSeconds}s",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Colors.blue;
      case 'mathematics':
        return Colors.purple;
      case 'language_arts':
        return Colors.green;
      case 'social_studies':
        return Colors.orange;
      case 'arts_creativity':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
