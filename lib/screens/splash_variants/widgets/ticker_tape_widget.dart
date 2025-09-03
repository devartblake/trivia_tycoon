import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TickerTapeWidget extends StatelessWidget {
  final bool reverse;
  const TickerTapeWidget({super.key, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    const tickerItems = [
      "🎩 Logic +12%",
      "🧠 Science +7%",
      "📚 History -1%",
      "🔢 Math +9%",
      "🎨 Art +4%",
    ];
    final text = tickerItems.join("   •   ");

    return SizedBox(
      height: 24,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: reverse,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text,
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        itemCount: 100,
      ).animate(onPlay: (controller) => controller.repeat()).slideX(
        begin: reverse ? 1 : -1,
        end: 0,
        duration: 6.seconds,
        curve: Curves.linear,
      ),
    );
  }
}