import 'package:flutter/material.dart';

/// ✅ CoinGainAnimation widget
/// Shows a floating, fading "+<amount>" when coins are added
class CoinGainAnimation extends StatefulWidget {
  final int amount;
  final Offset startOffset;

  const CoinGainAnimation({
    super.key,
    required this.amount,
    this.startOffset = const Offset(0, 0),
  });

  @override
  State<CoinGainAnimation> createState() => _CoinGainAnimationState();
}

class _CoinGainAnimationState extends State<CoinGainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.startOffset,
      end: widget.startOffset.translate(0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Text(
          "+${widget.amount}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
            shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(1, 1))],
          ),
        ),
      ),
    );
  }
}
