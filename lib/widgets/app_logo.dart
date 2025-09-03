import 'package:flutter/material.dart';
import '../core/constants/image_strings.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(tTriviaGameImage, height: 100),
        const SizedBox(height: 10),
        const Text(
          'QuizKwik',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
