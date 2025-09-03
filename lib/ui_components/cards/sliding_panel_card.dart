import 'package:flutter/material.dart';

class SlidingPanelCard extends StatefulWidget {
  final Widget mainContent;
  final Widget panelContent;

  const SlidingPanelCard({
    super.key,
    required this.mainContent,
    required this.panelContent,
  });

  @override
  State<SlidingPanelCard> createState() => _SlidingPanelCardState();
}

class _SlidingPanelCardState extends State<SlidingPanelCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _togglePanel() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              widget.mainContent,
              TextButton(
                onPressed: _togglePanel,
                child: const Text('More'),
              )
            ],
          ),
        ),
        Positioned.fill(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: widget.panelContent,
            ),
          ),
        )
      ],
    );
  }
}