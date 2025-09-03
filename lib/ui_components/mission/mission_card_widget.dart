import 'package:flutter/material.dart';
import '../../ui_components/mission/mission_swap_button.dart';
import '../progress_indicator/linear_progress_indicator.dart';

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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void _triggerSwap() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _controller.reverse();
    widget.onSwap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation.drive(Tween(begin: 1.0, end: 1.05)),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: 220,
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  _ProgressBarWithText(
                    progress: widget.progress,
                    total: widget.total,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(widget.badge),
                        backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                        shape: StadiumBorder(),
                      ),
                      Row(
                        children: [
                          Text("+${widget.reward}",
                              style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: -18,
                right: -16,
                child: MissionSwapButton(
                  onPressed: () => _showSwapModal(
                      context,
                    currentTitle: widget.title,
                    currentProgress: widget.progress,
                    currentTotal: widget.total,
                    currentReward: widget.reward,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSwapModal(BuildContext context, {
    required String currentTitle,
    required int currentProgress,
    required int currentTotal,
    required int currentReward,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Want to swap the mission?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "A new mission is ready for you! Keep in mind you will get a new one randomly assigned and you'll lose the progress in this one.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Mission Card Preview
            Card(
              color: Colors.deepPurple.shade50,
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TycoonLinearProgressIndicator(
                      value: (currentProgress / currentTotal).clamp(0.0, 1.0),
                      maxValue: 1.0,
                      minHeight: 16,
                      borderRadius: 8,
                      linearProgressBarBorderRadius: 6,
                      colorLinearProgress: Colors.deepPurple,
                      backgroundColor: Colors.deepPurple.shade100,
                      showGlowOnComplete: true,
                      trailingXpIcon: const Icon(Icons.flash_on_rounded, color: Colors.deepPurpleAccent, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$currentProgress / $currentTotal"),
                        Row(
                          children: [
                            Text("$currentReward", style: const TextStyle(color: Colors.deepOrange)),
                            const Icon(Icons.star, color: Colors.amber),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Swap button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _triggerSwap();
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text("Swap Mission"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
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

    return SizedBox(
      height: 24, // safely constrain height
      child: Stack(
        alignment: Alignment.center,
        children: [
          TycoonLinearProgressIndicator(
            value: value,
            maxValue: 1.0,
            minHeight: 20,
            showGlowOnComplete: true,
            animateXpOnComplete: true,
            gradientColors: const [Colors.blueAccent, Colors.lightBlue],
            borderRadius: 12,
            linearProgressBarBorderRadius: 8,
            colorLinearProgress: Colors.blueAccent,
            backgroundColor: Colors.grey.shade300,
            trailingXpIcon: const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
            showPercent: false,
            percentTextStyle: const TextStyle(color: Colors.white),
            alignment: Alignment.center,
            onProgressChanged: (_) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$progress",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$total",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

