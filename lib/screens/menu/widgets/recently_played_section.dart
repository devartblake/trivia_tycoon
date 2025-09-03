import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'quiz_card.dart';

class RecentlyPlayedSection extends StatelessWidget {
  final List<Map<String, String>> quizzes;
  final String ageGroup;

  const RecentlyPlayedSection({
    super.key,
    required this.quizzes,
    required this.ageGroup,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = _getTitleStyle();
    final accentColor = _getAccentColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recently Played', style: titleStyle),
            TextButton(
              onPressed: () => context.push('/quiz-history'),
              child: Text('View All', style: TextStyle(fontSize: 16, color: accentColor)),
            ),
          ],
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quizzes.length,
            itemBuilder: (context, index) => QuizCard(quiz: quizzes[index]),
          ),
        ),
      ],
    );
  }

  TextStyle _getTitleStyle() {
    return ageGroup == 'kids'
        ? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)
        : const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueAccent);
  }

  Color _getAccentColor() {
    return ageGroup == 'kids' ? Colors.pinkAccent : Colors.blueAccent;
  }
}
