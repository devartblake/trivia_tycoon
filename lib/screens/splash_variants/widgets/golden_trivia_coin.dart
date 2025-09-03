import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GoldenTriviaCoin extends StatelessWidget {
  const GoldenTriviaCoin({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.monetization_on_rounded,
      color: Colors.amberAccent,
      size: 100,
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds);
  }
}