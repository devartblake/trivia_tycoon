import 'package:flutter/material.dart';

class AnswerFeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final VoidCallback onNext;

  const AnswerFeedbackDialog({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isCorrect ? Colors.green : Colors.red;
    final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final String title = isCorrect ? "Correct!" : "Incorrect";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Answer: $correctAnswer", style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text("Next", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
