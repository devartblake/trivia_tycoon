import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GridCategorySection extends StatelessWidget {
  const GridCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Explore Classes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push('/all-classes');
              },
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _ClassCard(
              title: "Class 6",
              subtitle: "12 Quiz",
              color: Colors.purple.shade300,
              onTap: () {
                context.push('/class-quiz/6');
              },
            ),
            _ClassCard(
              title: "Class 7",
              subtitle: "17 Quiz",
              color: Colors.orange.shade300,
              onTap: () {
                context.push('/class-quiz/7');
              },
            ),
            _ClassCard(
              title: "Class 9",
              subtitle: "8 Quiz",
              color: Colors.blue.shade300,
              onTap: () {
                context.push('/class-quiz/9');
              },
            ),
            _ClassCard(
              title: "Class 8",
              subtitle: "21 Quiz",
              color: Colors.green.shade300,
              onTap: () {
                context.push('/class-quiz/8');
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Categories",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push('/all-categories');
              },
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _CategoryCard(
              title: "Science",
              icon: Icons.science,
              color: Colors.blue,
              questionCount: 45,
              onTap: () {
                context.push('/category-quiz/science');
              },
            ),
            _CategoryCard(
              title: "History",
              icon: Icons.history_edu,
              color: Colors.brown,
              questionCount: 38,
              onTap: () {
                context.push('/category-quiz/history');
              },
            ),
            _CategoryCard(
              title: "Sports",
              icon: Icons.sports_soccer,
              color: Colors.green,
              questionCount: 52,
              onTap: () {
                context.push('/category-quiz/sports');
              },
            ),
            _CategoryCard(
              title: "Geography",
              icon: Icons.public,
              color: Colors.teal,
              questionCount: 41,
              onTap: () {
                context.push('/category-quiz/geography');
              },
            ),
            _CategoryCard(
              title: "Technology",
              icon: Icons.computer,
              color: Colors.purple,
              questionCount: 33,
              onTap: () {
                context.push('/category-quiz/technology');
              },
            ),
            _CategoryCard(
              title: "Literature",
              icon: Icons.menu_book,
              color: Colors.orange,
              questionCount: 29,
              onTap: () {
                context.push('/category-quiz/literature');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ClassCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int questionCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.questionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$questionCount questions",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
