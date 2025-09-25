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
        color: const Color(0xFF2C2C54).withOpacity(0.95),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.8),
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
                      const Color(0xFF6C5CE7).withOpacity(0.3),
                      const Color(0xFF5A4FCF).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
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
                      backgroundColor: Colors.white.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.8),
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
                            const Icon(Icons.star, color: Colors.amber, size: 16),
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
                            color: Colors.white.withOpacity(0.3),
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

class _MissionCardState extends State<MissionCard> with TickerProviderStateMixin {
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

  void _triggerSwap() async {
    await _controller!.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _controller!.reverse();
    widget.onSwap();
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
      width: 280,
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [
            const Color(0xFF1B4332).withOpacity(0.95),
            const Color(0xFF2D5A3D).withOpacity(0.9),
          ]
              : [
            const Color(0xFF2C2C54).withOpacity(0.95),
            const Color(0xFF1B1B2F).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF40916C).withOpacity(0.6)
              : Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? const Color(0xFF40916C).withOpacity(0.3)
                : Colors.black.withOpacity(0.25),
            blurRadius: isCompleted ? 20 : 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _CardPatternPainter(isCompleted: isCompleted),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTitle(),
                  const Spacer(),
                  _buildProgressSection(),
                  const SizedBox(height: 16),
                  _buildFooter(isCompleted),
                ],
              ),
            ),
            // Completion overlay
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF40916C).withOpacity(0.1),
                        const Color(0xFF52B788).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isCompleted = widget.progress >= widget.total;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            color: isCompleted ? Colors.white : const Color(0xFF74C0FC),
            size: 20,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getBadgeColor().withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBadgeColor().withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            widget.badge,
            style: TextStyle(
              color: _getBadgeColor(),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.white,
        height: 1.3,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressSection() {
    return _ProgressBarWithText(
      progress: widget.progress,
      total: widget.total,
    );
  }

  Widget _buildFooter(bool isCompleted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF40916C).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF52B788).withOpacity(0.7),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Color(0xFF95D5B2), size: 14),
                SizedBox(width: 4),
                Text(
                  "Complete",
                  style: TextStyle(
                    color: Color(0xFF95D5B2),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8500).withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "In Progress",
              style: TextStyle(
                color: Color(0xFFFFB366),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD60A).withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD60A).withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "+${widget.reward}",
                style: const TextStyle(
                  color: Color(0xFFFFD60A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Color(0xFFFFD60A), size: 14),
            ],
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

  const _ProgressBarWithText({
    required this.progress,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final value = (progress / total).clamp(0.0, 1.0);
    final isCompleted = progress >= total;

    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TycoonLinearProgressIndicator(
            value: value,
            maxValue: 1.0,
            minHeight: 24,
            showGlowOnComplete: true,
            animateXpOnComplete: true,
            gradientColors: isCompleted
                ? [const Color(0xFF52B788), const Color(0xFF40916C)]
                : [const Color(0xFF6C5CE7), const Color(0xFF5A4FCF)],
            borderRadius: 14,
            linearProgressBarBorderRadius: 12,
            colorLinearProgress: isCompleted
                ? const Color(0xFF52B788)
                : const Color(0xFF6C5CE7),
            backgroundColor: Colors.white.withOpacity(0.2),
            trailingXpIcon: Icon(
              isCompleted ? Icons.check_circle : Icons.flash_on_rounded,
              color: Colors.white,
              size: 18,
            ),
            showPercent: false,
            percentTextStyle: const TextStyle(color: Colors.white),
            alignment: Alignment.center,
            onProgressChanged: (_) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$progress",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "$total",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      ..color = Colors.white.withOpacity(0.03)
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