import 'package:flutter/material.dart';
import '../../../game/controllers/word_search_controller.dart';

class WordList extends StatelessWidget {
  final WordSearchController controller;

  const WordList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: controller.words.map((word) {
            final found = controller.foundWords.contains(word);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    found ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (found)
                    const Icon(Icons.check, color: Colors.white, size: 16),
                  if (found) const SizedBox(width: 4),
                  Text(
                    word,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      decoration: found ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
