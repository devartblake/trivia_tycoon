import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TypingTriviaLogo extends StatelessWidget {
  const TypingTriviaLogo({super.key});

  @override
  Widget build(BuildContext context) {
    const text = "Trivia Tycoon";
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.characters.map((char) {
        return Text(
          char,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ).animate().fadeIn(duration: 400.ms).moveX(begin: -10).then();
      }).toList(),
    );
  }
}

