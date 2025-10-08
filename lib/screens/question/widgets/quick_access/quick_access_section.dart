import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/quick_access/quick_access_card.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickAccessCard(
                title: 'Random Quiz',
                subtitle: 'Mixed questions',
                icon: Icons.shuffle,
                color: Colors.indigo,
                onTap: () {
                  context.push('/quiz/random');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAccessCard(
                title: 'Daily Challenge',
                subtitle: 'New every day',
                icon: Icons.calendar_today,
                color: Colors.teal,
                onTap: () {
                  context.push('/quiz/daily');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
