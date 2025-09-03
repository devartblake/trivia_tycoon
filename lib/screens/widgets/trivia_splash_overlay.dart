import 'package:flutter/material.dart';

class TriviaSplashOverlay extends StatelessWidget {
  const TriviaSplashOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlutterLogo(size: 120),
          const SizedBox(height: 20),
          Text(
            "Trivia Tycoon",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}