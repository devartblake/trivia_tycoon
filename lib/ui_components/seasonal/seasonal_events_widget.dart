import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SeasonalEventsWidget extends StatefulWidget {
  const SeasonalEventsWidget({super.key});

  @override
  State<SeasonalEventsWidget> createState() => _SeasonalEventsWidgetState();
}

class _SeasonalEventsWidgetState extends State<SeasonalEventsWidget>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _pulseAnimation;

  // Mock seasonal event data
  final Map<String, dynamic> _currentEvent = {
    'name': 'EASTER SEASON',
    'icon': Icons.egg,
    'endTime': '01d 04h',
    'theme': 'easter',
    'rewards': [
      {'label': 'x1', 'icon': Icons.check_circle, 'claimed': true, 'type': 'bonus'},
      {'label': 'x5000', 'icon': Icons.monetization_on_outlined, 'claimed': false, 'type': 'coins'},
      {'label': 'x50', 'icon': Icons.card_giftcard, 'claimed': false, 'type': 'gems'},
    ],
    'progress': 33, // percentage
    'description': 'Celebrate the season with special rewards!',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    _animationController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToSeasonalEventsScreen(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: _getSeasonalGradient(_currentEvent['theme']),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _getSeasonalColor(_currentEvent['theme']).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _SeasonalPatternPainter(theme: _currentEvent['theme']),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildProgressSection(),
                    const SizedBox(height: 16),
                    _buildRewardsPreview(),
                  ],
                ),
              ),
              // Tap indicator
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _pulseAnimation != null
            ? AnimatedBuilder(
          animation: _pulseAnimation!,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation!.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _currentEvent['icon'],
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        )
            : Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _currentEvent['icon'],
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentEvent['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Ends in ${_currentEvent['endTime']}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final progress = _currentEvent['progress'] / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _currentEvent['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              "${_currentEvent['progress']}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _currentEvent['rewards'].take(3).map<Widget>((reward) {
        return _buildRewardItem(reward);
      }).toList(),
    );
  }

  Widget _buildRewardItem(Map<String, dynamic> reward) {
    final isClaimed = reward['claimed'] as bool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isClaimed ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimed
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isClaimed ? Colors.green : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isClaimed ? Icons.check : reward['icon'],
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            reward['label'],
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              decoration: isClaimed ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getSeasonalGradient(String theme) {
    switch (theme) {
      case 'easter':
        return LinearGradient(
          colors: [
            Colors.pink.shade300,
            Colors.purple.shade400,
            Colors.pink.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'halloween':
        return LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade500,
            Colors.red.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'christmas':
        return LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.green.shade500,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade500,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getSeasonalColor(String theme) {
    switch (theme) {
      case 'easter':
        return Colors.pink;
      case 'halloween':
        return Colors.orange;
      case 'christmas':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _navigateToSeasonalEventsScreen(BuildContext context) {
    // Navigate to seasonal events screen
    // context.push('/seasonal-events');

    // For now, show a temporary message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 12),
            Text('Opening Seasonal Events Screen...'),
          ],
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SeasonalPatternPainter extends CustomPainter {
  final String theme;

  _SeasonalPatternPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    switch (theme) {
      case 'easter':
        _drawEasterPattern(canvas, size, paint);
        break;
      case 'halloween':
        _drawHalloweenPattern(canvas, size, paint);
        break;
      case 'christmas':
        _drawChristmasPattern(canvas, size, paint);
        break;
      default:
        _drawDefaultPattern(canvas, size, paint);
    }
  }

  void _drawEasterPattern(Canvas canvas, Size size, Paint paint) {
    // Draw egg shapes
    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        size.width * 0.8 + (i * 15),
        size.height * 0.2 + (i * 25),
        12,
        18,
      );
      canvas.drawOval(rect, paint);
    }

    // Draw small circles (bubbles)
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(20 + (i * 30), size.height * 0.8),
        6,
        paint,
      );
    }
  }

  void _drawHalloweenPattern(Canvas canvas, Size size, Paint paint) {
    // Draw pumpkin-like circles
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.9, 20 + (i * 30)),
        8,
        paint,
      );
    }
  }

  void _drawChristmasPattern(Canvas canvas, Size size, Paint paint) {
    // Draw tree triangles
    final path = Path();
    path.moveTo(size.width * 0.85, size.height * 0.3);
    path.lineTo(size.width * 0.95, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDefaultPattern(Canvas canvas, Size size, Paint paint) {
    // Draw simple geometric shapes
    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        size.width * 0.8 + (i * 20),
        size.height * 0.3 + (i * 20),
        15,
        15,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
