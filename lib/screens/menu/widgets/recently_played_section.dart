import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'quiz_card.dart';

class RecentlyPlayedSection extends StatefulWidget {
  final List<Map<String, String>> quizzes;
  final String ageGroup;

  const RecentlyPlayedSection({
    super.key,
    required this.quizzes,
    required this.ageGroup,
  });

  @override
  State<RecentlyPlayedSection> createState() => _RecentlyPlayedSectionState();
}

class _RecentlyPlayedSectionState extends State<RecentlyPlayedSection>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    // Start animation with a delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animationController!.forward();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeData();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (theme['accentColor'] as Color).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: (theme['accentColor'] as Color).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 20),
          _buildQuizList(),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> theme) {
    return _fadeAnimation != null
        ? FadeTransition(
      opacity: _fadeAnimation!,
      child: _headerContent(theme),
    )
        : _headerContent(theme);
  }

  Widget _headerContent(Map<String, dynamic> theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: theme['gradient'] as LinearGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (theme['accentColor'] as Color).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.history,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recently Played',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.quizzes.length} quizzes completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: (theme['accentColor'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (theme['accentColor'] as Color).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextButton(
            onPressed: () => context.push('/quiz-history'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme['accentColor'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: theme['accentColor'] as Color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizList() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.quizzes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 150)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: QuizCard(
                    quiz: widget.quizzes[index],
                    ageGroup: widget.ageGroup,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getThemeData() {
    switch (widget.ageGroup) {
      case 'kids':
        return {
          'accentColor': const Color(0xFFFF6B6B),
          'gradient': const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
        };
      case 'teens':
        return {
          'accentColor': const Color(0xFF4ECDC4),
          'gradient': const LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          ),
        };
      case 'adults':
        return {
          'accentColor': const Color(0xFF667eea),
          'gradient': const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        };
      default:
        return {
          'accentColor': const Color(0xFF6366F1),
          'gradient': const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        };
    }
  }
}
