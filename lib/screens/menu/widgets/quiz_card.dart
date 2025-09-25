import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizCard extends StatefulWidget {
  final Map<String, String> quiz;
  final String? ageGroup;

  const QuizCard({
    super.key,
    required this.quiz,
    this.ageGroup,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> with SingleTickerProviderStateMixin {
  AnimationController? _hoverController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController!,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = _parseScore(widget.quiz['score'] ?? '0%');
    final scoreColor = _getScoreColor(score);
    final theme = _getThemeData();

    return GestureDetector(
      onTapDown: (_) => _hoverController!.forward(),
      onTapUp: (_) {
        _hoverController!.reverse();
        context.push('/quiz-details', extra: widget.quiz);
      },
      onTapCancel: () => _hoverController!.reverse(),
      child: _scaleAnimation != null && _elevationAnimation != null
          ? AnimatedBuilder(
        animation: _hoverController!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation!.value,
            child: _buildCard(scoreColor, theme, _elevationAnimation!.value),
          );
        },
      )
          : _buildCard(scoreColor, theme, 0.0),
    );
  }

  Widget _buildCard(Color scoreColor, Map<String, dynamic> theme, double elevationValue) {
    final score = _parseScore(widget.quiz['score'] ?? '0%');

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 15 + (10 * elevationValue),
            offset: Offset(0, 5 + (5 * elevationValue)),
          ),
          if (elevationValue > 0)
            BoxShadow(
              color: scoreColor.withOpacity(0.2 * elevationValue),
              blurRadius: 20,
              offset: const Offset(0, 0),
            ),
        ],
        border: Border.all(
          color: scoreColor.withOpacity(0.1 + (0.1 * elevationValue)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(scoreColor),
          _buildContentSection(score, scoreColor),
        ],
      ),
    );
  }

  Widget _buildImageSection(Color scoreColor) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withOpacity(0.8),
                  scoreColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: widget.quiz['image'] != null
                ? ColorFiltered(
              colorFilter: ColorFilter.mode(
                scoreColor.withOpacity(0.3),
                BlendMode.overlay,
              ),
              child: Image.asset(
                widget.quiz['image']!,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage(scoreColor);
                },
              ),
            )
                : _buildFallbackImage(scoreColor),
          ),
        ),
        // Score badge
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scoreColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.quiz['score'] ?? '0%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ),
        // Category icon
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              _getCategoryIcon(widget.quiz['title'] ?? ''),
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage(Color scoreColor) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withOpacity(0.6),
            scoreColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        _getCategoryIcon(widget.quiz['title'] ?? ''),
        color: Colors.white.withOpacity(0.8),
        size: 32,
      ),
    );
  }

  Widget _buildContentSection(int score, Color scoreColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.quiz['title'] ?? 'Quiz',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getScoreIcon(score),
                  size: 11,
                  color: scoreColor,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    _getScoreLabel(score),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: scoreColor,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 11,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    widget.quiz['date'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: scoreColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 7,
                    color: scoreColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _parseScore(String scoreStr) {
    return int.tryParse(scoreStr.replaceAll('%', '')) ?? 0;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFFF59E0B); // Yellow
    if (score >= 40) return const Color(0xFFEF4444); // Orange-red
    return const Color(0xFFDC2626); // Red
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.trending_up;
    return Icons.trending_down;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  IconData _getCategoryIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('science')) return Icons.science;
    if (titleLower.contains('history')) return Icons.history_edu;
    if (titleLower.contains('pop culture') || titleLower.contains('culture')) return Icons.trending_up;
    if (titleLower.contains('movie') || titleLower.contains('film') || titleLower.contains('cinema')) return Icons.movie;
    if (titleLower.contains('sport')) return Icons.sports_soccer;
    if (titleLower.contains('music')) return Icons.music_note;
    if (titleLower.contains('art')) return Icons.palette;
    if (titleLower.contains('geography')) return Icons.public;
    if (titleLower.contains('math')) return Icons.calculate;
    return Icons.quiz;
  }

  Map<String, dynamic> _getThemeData() {
    switch (widget.ageGroup) {
      case 'kids':
        return {
          'primaryColor': const Color(0xFFFF6B6B),
          'secondaryColor': const Color(0xFFFF8E53),
        };
      case 'teens':
        return {
          'primaryColor': const Color(0xFF4ECDC4),
          'secondaryColor': const Color(0xFF44A08D),
        };
      case 'adults':
        return {
          'primaryColor': const Color(0xFF667eea),
          'secondaryColor': const Color(0xFF764ba2),
        };
      default:
        return {
          'primaryColor': const Color(0xFF6366F1),
          'secondaryColor': const Color(0xFF8B5CF6),
        };
    }
  }
}
