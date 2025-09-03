import 'package:flutter/material.dart';

class BackgroundParallax extends StatelessWidget {
  const BackgroundParallax({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([]), // insert Ticker or use AnimatedController if needed
      builder: (context, child) => Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}