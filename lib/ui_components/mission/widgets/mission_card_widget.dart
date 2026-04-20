import 'package:flutter/material.dart';
import '../../progress_indicator/linear_progress_indicator.dart';

// External swap button widget that can be positioned independently
class MissionSwapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MissionSwapButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2C54).withValues(alpha: 0.95),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.refresh,
          color: Colors.white70,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: "Swap mission",
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

// Wrapper widget that combines MissionCard with positioned swap button
class MissionCardWithSwapButton extends StatelessWidget {
  final String title;
  final int progress;
  final int total;
  final int reward;
  final IconData icon;
  final String badge;
  final VoidCallback onSwap;

  const MissionCardWithSwapButton({
    super.key,
    required this.title,
    required this.progress,
    required this.total,
    required this.reward,
    required this.icon,
    required this.badge,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MissionCard(
          title: title,
          progress: progress,
          total: total,
          reward: reward,
          icon: icon,
          badge: badge,
          onSwap: onSwap,
        ),
        Positioned(
          top: -8,
          right: -8,
          child: MissionSwapButton(
            onPressed: () => MissionCardWithSwapButton._showSwapModal(
              context,
              currentTitle: title,
              currentProgress: progress,
              currentTotal: total,
              currentReward: reward,
              onSwap: onSwap,
            ),
          ),
        ),
      ],
    );
  }

  static void _showSwapModal(
    BuildContext context, {
    required String currentTitle,
    required int currentProgress,
    required int currentTotal,
    required int currentReward,
    required VoidCallback onSwap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Swap Mission?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "A new mission is ready for you! Keep in mind you will get a new one randomly assigned and you'll lose the progress in this one.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Mission Card Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      const Color(0xFF5A4FCF).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TycoonLinearProgressIndicator(
                      value: (currentProgress / currentTotal).clamp(0.0, 1.0),
                      maxValue: 1.0,
                      minHeight: 16,
                      borderRadius: 8,
                      linearProgressBarBorderRadius: 6,
                      colorLinearProgress: const Color(0xFF6C5CE7),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      showGlowOnComplete: true,
                      trailingXpIcon: const Icon(
                        Icons.flash_on_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$currentProgress / $currentTotal",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "$currentReward",
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onSwap();
                      },
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      label: const Text("Swap Mission"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class MissionCard extends StatefulWidget {
  final String title;
  final int progress;
  final int total;
  final int reward;
  final IconData icon;
  final String badge;
  final VoidCallback onSwap;

  const MissionCard({
    super.key,
    required this.title,
    required this.progress,
    required this.total,
    required this.reward,
    required this.icon,
    required this.badge,
    required this.onSwap,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  AnimationController? _glowController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    // Glow animation for completed missions
    if (widget.progress >= widget.total) {
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
      _glowController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.progress >= widget.total;

    return _scaleAnimation != null
        ? ScaleTransition(
            scale: _scaleAnimation!.drive(Tween(begin: 1.0, end: 1.05)),
            child: _buildCard(isCompleted),
          )
        : _buildCard(isCompleted);
  }

  Widget _buildCard(bool isCompleted) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
                  const Color(0xFF1B4332).withValues(alpha: 0.92),
                  const Color(0xFF2D5A3D).withValues(alpha: 0.88),
                ]
              : [
                  const Color(0xFF2C2C54).withValues(alpha: 0.92),
                  const Color(0xFF1B1B2F).withValues(alpha: 0.88),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF40916C).withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? const Color(0xFF40916C).withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CardPatternPainter(isCompleted: isCompleted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(isCompleted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(isCompleted),
                        const SizedBox(height: 10),
                        _buildProgressSection(isCompleted),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFooter(isCompleted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left side: icon container (feed-row style)
  Widget _buildHeader(bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Icon(
        widget.icon,
        color: isCompleted ? Colors.white : const Color(0xFF74C0FC),
        size: 20,
      ),
    );
  }

  /// Center top: title + badge (single row)
  Widget _buildTitle(bool isCompleted) {
    final badgeColor = _getBadgeColor();

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Text(
            widget.badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Center bottom: compact progress bar + progress text
  Widget _buildProgressSection(bool isCompleted) {
    final progressText = "${widget.progress}/${widget.total}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressBarWithText(
          progress: widget.progress,
          total: widget.total,
          compact: true,
        ),
        const SizedBox(height: 6),
        Text(
          progressText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Right side: reward pill + status/check
  Widget _buildFooter(bool isCompleted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD60A).withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "+${widget.reward}",
                style: const TextStyle(
                  color: Color(0xFFFFD60A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                color: Color(0xFFFFD60A),
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (isCompleted)
          const Icon(
            Icons.check_circle,
            color: Color(0xFF95D5B2),
            size: 18,
          )
        else
          Text(
            "In progress",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Color _getBadgeColor() {
    switch (widget.badge.toLowerCase()) {
      case 'science':
        return const Color(0xFF74C0FC);
      case 'streak master':
      case 'streak':
        return const Color(0xFFFFB366);
      case 'explorer':
        return const Color(0xFF95D5B2);
      case 'daily':
        return const Color(0xFFDDA0DD);
      case 'wildcard':
        return const Color(0xFFFF91A4);
      default:
        return const Color(0xFFADB5BD);
    }
  }
}

class _ProgressBarWithText extends StatelessWidget {
  final int progress;
  final int total;
  final bool compact;

  const _ProgressBarWithText({
    required this.progress,
    required this.total,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = (progress / total).clamp(0.0, 1.0);
    final isCompleted = progress >= total;

    final minHeight = compact ? 14.0 : 24.0;
    final radius = compact ? 10.0 : 14.0;
    final innerRadius = compact ? 9.0 : 12.0;

    return SizedBox(
      height: compact ? 16 : 28,
      child: TycoonLinearProgressIndicator(
        value: value,
        maxValue: 1.0,
        minHeight: minHeight,
        showGlowOnComplete: true,
        animateXpOnComplete: true,
        gradientColors: isCompleted
            ? [const Color(0xFF52B788), const Color(0xFF40916C)]
            : [const Color(0xFF6C5CE7), const Color(0xFF5A4FCF)],
        borderRadius: radius,
        linearProgressBarBorderRadius: innerRadius,
        colorLinearProgress:
            isCompleted ? const Color(0xFF52B788) : const Color(0xFF6C5CE7),
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        trailingXpIcon: Icon(
          isCompleted ? Icons.check_circle : Icons.flash_on_rounded,
          color: Colors.white,
          size: compact ? 14 : 18,
        ),
        showPercent: false,
        percentTextStyle: const TextStyle(color: Colors.white),
        alignment: Alignment.center,
        onProgressChanged: (_) {},
      ),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  final bool isCompleted;

  _CardPatternPainter({required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle geometric pattern
    for (int i = 0; i < 5; i++) {
      final rect = Rect.fromLTWH(
        size.width * 0.8 + (i * 10),
        -20 + (i * 20),
        30,
        30,
      );
      canvas.drawOval(rect, paint);
    }

    for (int i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        -15 + (i * 25),
        size.height * 0.7 + (i * 15),
        20,
        20,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
